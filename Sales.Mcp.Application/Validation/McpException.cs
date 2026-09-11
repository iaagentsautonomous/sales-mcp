
namespace Sales.Mcp.Application.Validation
{
    [Serializable]
    internal class McpException : Exception
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