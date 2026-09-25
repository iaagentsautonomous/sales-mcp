
namespace Sales.Mcp.Application.Validation
{
    [Serializable]
    public class McpException : Exception
    {
        public McpException()
        {
        }

        public McpException(string? message) : base(message)
        {
        }

        public McpException(string? message, Exception? innerException) : base(message, innerException)
        {
        }
    }
}