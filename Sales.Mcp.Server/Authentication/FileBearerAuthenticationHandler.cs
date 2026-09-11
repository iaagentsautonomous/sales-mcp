using System.Collections.Concurrent;
using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Sales.Mcp.Server.Authentication;

public sealed class FileBearerAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly FileTokenProvider _tokenProvider;
    private static readonly ConcurrentDictionary<string, FailedAttempts> _failedAttempts = new(StringComparer.OrdinalIgnoreCase);

    // Constantes de proteção contra brute-force
    private const int MaxFailedAttemptsBeforeDelay = 3;
    private const int InitialDelayMs = 1000;
    private const int MaxDelayMs = 30000;
    private static readonly TimeSpan AttemptWindow = TimeSpan.FromMinutes(5);

    public FileBearerAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        FileTokenProvider tokenProvider)
        : base(options, logger, encoder)
    {
        _tokenProvider = tokenProvider;
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("Authorization", out var authorizationHeader))
        {
            return AuthenticateResult.NoResult();
        }

        var headerValue = authorizationHeader.ToString();
        if (!headerValue.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return AuthenticateResult.Fail("Esquema de autorizacao invalido.");
        }

        var providedToken = headerValue["Bearer ".Length..].Trim();
        if (string.IsNullOrWhiteSpace(providedToken))
        {
            return AuthenticateResult.Fail("Bearer token ausente.");
        }

        // Obtém o IP do cliente para rastreamento de tentativas
        var clientIp = GetClientIp();

        // Aplica delay progressivo se houver muitas tentativas falhas
        await ApplyBruteForceDelayAsync(clientIp);

        string expectedToken;
        try
        {
            expectedToken = _tokenProvider.GetRequiredToken();
        }
        catch (Exception ex)
        {
            return AuthenticateResult.Fail(ex.Message);
        }

        if (!string.Equals(providedToken, expectedToken, StringComparison.Ordinal))
        {
            // Registra tentativa falha e aplica delay
            RecordFailedAttempt(clientIp);
            Logger.LogWarning("Tentativa de autenticação inválida. IP={ClientIp}", clientIp);
            return AuthenticateResult.Fail("Bearer token invalido.");
        }

        // Limpa tentativas falhas em caso de sucesso
        _failedAttempts.TryRemove(clientIp, out _);

        var identity = new ClaimsIdentity(
        [
            new Claim(ClaimTypes.NameIdentifier, "mcp-client"),
            new Claim(ClaimTypes.Name, "mcp-client")
        ], Scheme.Name);

        return AuthenticateResult.Success(new AuthenticationTicket(new ClaimsPrincipal(identity), Scheme.Name));
    }

    private string GetClientIp()
    {
        // Tenta obter IP real atrás de proxy/reverse proxy
        var forwardedFor = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(forwardedFor))
        {
            return forwardedFor.Split(',')[0].Trim();
        }

        return Request.HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }

    private async Task ApplyBruteForceDelayAsync(string clientIp)
    {
        if (_failedAttempts.TryGetValue(clientIp, out var attempts))
        {
            // Limpa entradas expiradas
            if (DateTime.UtcNow - attempts.LastAttempt > AttemptWindow)
            {
                _failedAttempts.TryRemove(clientIp, out _);
                return;
            }

            // Aplica delay progressivo: 1s, 2s, 4s, 8s, 16s, 30s (máx)
            if (attempts.Count >= MaxFailedAttemptsBeforeDelay)
            {
                var delayMs = Math.Min(
                    InitialDelayMs * (int)Math.Pow(2, attempts.Count - MaxFailedAttemptsBeforeDelay),
                    MaxDelayMs);
                await Task.Delay(delayMs);
            }
        }
    }

    private void RecordFailedAttempt(string clientIp)
    {
        var now = DateTime.UtcNow;
        _failedAttempts.AddOrUpdate(clientIp,
            _ => new FailedAttempts { Count = 1, LastAttempt = now },
            (_, existing) =>
            {
                // Reseta o contador se a janela de tempo expirou
                if (now - existing.LastAttempt > AttemptWindow)
                {
                    return new FailedAttempts { Count = 1, LastAttempt = now };
                }
                return new FailedAttempts { Count = existing.Count + 1, LastAttempt = now };
            });
    }

    private sealed class FailedAttempts
    {
        public int Count { get; set; }
        public DateTime LastAttempt { get; set; }
    }
}
