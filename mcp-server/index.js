const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { CallToolRequestSchema, ListToolsRequestSchema } = require("@modelcontextprotocol/sdk/types.js");
const axios = require("axios");

// Configuration
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || "https://your-n8n-instance.com/webhook/mcp-bridge";

const server = new Server(
  {
    name: "crisis-sync-comms",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * Define available tools for the AI
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "send_crisis_alert",
        description: "Sends a real-time alert to WhatsApp, Slack, and Gmail via n8n",
        inputSchema: {
          type: "object",
          properties: {
            title: { type: "string", description: "Incident title" },
            message: { type: "string", description: "Emergency message content" },
            severity: { type: "string", enum: ["critical", "high", "medium", "low"] },
            channels: { 
              type: "array", 
              items: { type: "string", enum: ["whatsapp", "slack", "gmail"] },
              description: "Target communication channels"
            },
          },
          required: ["title", "message", "severity", "channels"],
        },
      },
    ],
  };
});

/**
 * Handle tool execution
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "send_crisis_alert") {
    const { title, message, severity, channels } = request.params.arguments;
    
    try {
      await axios.post(N8N_WEBHOOK_URL, {
        source: "mcp_ai_assistant",
        title,
        message,
        severity,
        channels
      });

      return {
        content: [{ type: "text", text: `Successfully triggered broadcast to: ${channels.join(", ")}` }],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error connecting to n8n: ${error.message}` }],
        isError: true,
      };
    }
  }

  throw new Error("Tool not found");
});

/**
 * Start the server
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("CrisisSync MCP Server running on stdio");
}

main().catch(console.error);
