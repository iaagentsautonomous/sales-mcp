// Dados das ferramentas MCP para documentação
const mcpTools = [
    {
        id: "get_revenue_by_period",
        name: "get_revenue_by_period",
        title: "Revenue by period",
        description: "Retorna faturamento bruto e reembolsado por dia, mes ou ano dentro de um intervalo.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            },
            {
                name: "groupBy",
                type: "string",
                required: true,
                description: "Agrupamento permitido: day, month ou year.",
                allowedValues: ["day", "month", "year"],
                example: "month"
            }
        ],
        responseStructure: {
            type: "RevenueByPeriodResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período analisado" },
                { name: "EndDate", type: "string", description: "Data final do período analisado" },
                { name: "GroupBy", type: "string", description: "Tipo de agrupamento utilizado" },
                { 
                    name: "Points", 
                    type: "RevenuePointDto[]", 
                    description: "Lista de pontos de faturamento",
                    subfields: [
                        { name: "PeriodStart", type: "string", description: "Início do período (data ou mês/ano)" },
                        { name: "GrossRevenue", type: "decimal", description: "Faturamento bruto no período" },
                        { name: "RefundedRevenue", type: "decimal", description: "Valor reembolsado no período" },
                        { name: "OrderCount", type: "int", description: "Número de pedidos no período" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_revenue_by_period",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "groupBy": "month"
    }
  },
  "id": 1
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "GroupBy": "month",
    "Points": [
      {
        "PeriodStart": "2025-01-01",
        "GrossRevenue": 125000.50,
        "RefundedRevenue": 2500.00,
        "OrderCount": 45
      },
      {
        "PeriodStart": "2025-02-01",
        "GrossRevenue": 138750.25,
        "RefundedRevenue": 1875.50,
        "OrderCount": 52
      }
    ]
  },
  "id": 1
}`
            },
            cline: `// Usando access_mcp_resource no Cline
{
  "tool": "access_mcp_resource",
  "params": {
    "server_name": "sales-analytics",
    "uri": "tool://sales-analytics/get_revenue_by_period",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "groupBy": "month"
    }
  }
}

// Ou usando execute_command
{
  "tool": "execute_command",
  "params": {
    "command": "curl -X POST http://localhost:5000/mcp/tools/call \\\\n  -H \\"Authorization: Bearer TOKEN_JWT\\" \\\\n  -H \\"Content-Type: application/json\\" \\\\n  -d '{\\"jsonrpc\\":\\"2.0\\",\\"method\\":\\"tools/call\\",\\"params\\":{\\"name\\":\\"get_revenue_by_period\\",\\"arguments\\":{\\"startDate\\":\\"2025-01-01\\",\\"endDate\\":\\"2025-12-31\\",\\"groupBy\\":\\"month\\"}},\\"id\\":1}'",
    "requires_approval": false
  }
}`
        },
        useCases: [
            "Analisar sazonalidade do faturamento ao longo do ano",
            "Comparar performance mensal entre diferentes anos",
            "Identificar períodos com maior taxa de reembolsos",
            "Acompanhar crescimento do faturamento trimestral"
        ]
    },
    {
        id: "get_top_products",
        name: "get_top_products",
        title: "Top products",
        description: "Retorna os produtos com maior volume de vendas ou maior valor liquido vendido.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            },
            {
                name: "limit",
                type: "int",
                required: true,
                description: "Quantidade maxima de itens retornados.",
                example: 10
            },
            {
                name: "sortBy",
                type: "string",
                required: true,
                description: "Ordenacao permitida: unitsSold ou netSales.",
                allowedValues: ["unitsSold", "netSales"],
                example: "netSales"
            }
        ],
        responseStructure: {
            type: "TopProductsResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { name: "Limit", type: "int", description: "Número máximo de produtos retornados" },
                { name: "SortBy", type: "string", description: "Critério de ordenação utilizado" },
                { 
                    name: "Items", 
                    type: "TopProductDto[]", 
                    description: "Lista dos produtos mais vendidos",
                    subfields: [
                        { name: "ProductName", type: "string", description: "Nome do produto" },
                        { name: "UnitsSold", type: "int", description: "Quantidade de unidades vendidas" },
                        { name: "NetSales", type: "decimal", description: "Valor líquido de vendas (após descontos)" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_top_products",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "limit": 10,
      "sortBy": "netSales"
    }
  },
  "id": 2
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Limit": 10,
    "SortBy": "netSales",
    "Items": [
      {
        "ProductName": "Smartphone Premium X1",
        "UnitsSold": 1250,
        "NetSales": 1875000.00
      },
      {
        "ProductName": "Notebook Business Pro",
        "UnitsSold": 890,
        "NetSales": 1563200.00
      }
    ]
  },
  "id": 2
}`
            }
        },
        useCases: [
            "Identificar produtos com maior margem de lucro",
            "Analisar sazonalidade de produtos específicos",
            "Otimizar estoque com base nos produtos mais vendidos",
            "Desenvolver estratégias de upsell/cross-sell"
        ]
    },
    {
        id: "get_top_customers",
        name: "get_top_customers",
        title: "Top customers",
        description: "Retorna os clientes com maior faturamento ou maior numero de pedidos.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            },
            {
                name: "limit",
                type: "int",
                required: true,
                description: "Quantidade maxima de itens retornados.",
                example: 20
            },
            {
                name: "sortBy",
                type: "string",
                required: true,
                description: "Ordenacao permitida: grossSales ou orderCount.",
                allowedValues: ["grossSales", "orderCount"],
                example: "grossSales"
            }
        ],
        responseStructure: {
            type: "TopCustomersResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { name: "Limit", type: "int", description: "Número máximo de clientes retornados" },
                { name: "SortBy", type: "string", description: "Critério de ordenação utilizado" },
                { 
                    name: "Items", 
                    type: "TopCustomerDto[]", 
                    description: "Lista dos clientes mais valiosos",
                    subfields: [
                        { name: "CustomerCode", type: "string", description: "Código único do cliente" },
                        { name: "CustomerName", type: "string", description: "Nome do cliente" },
                        { name: "OrderCount", type: "int", description: "Número total de pedidos" },
                        { name: "GrossSales", type: "decimal", description: "Faturamento total gerado" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_top_customers",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "limit": 20,
      "sortBy": "grossSales"
    }
  },
  "id": 3
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Limit": 20,
    "SortBy": "grossSales",
    "Items": [
      {
        "CustomerCode": "CUS000123",
        "CustomerName": "Empresa ABC Ltda",
        "OrderCount": 45,
        "GrossSales": 1250000.00
      },
      {
        "CustomerCode": "CUS000456",
        "CustomerName": "Companhia XYZ S.A.",
        "OrderCount": 32,
        "GrossSales": 980000.00
      }
    ]
  },
  "id": 3
}`
            }
        },
        useCases: [
            "Identificar clientes com maior valor vitalício (LTV)",
            "Desenvolver programas de fidelidade para clientes premium",
            "Analisar padrões de compra de clientes recorrentes",
            "Segmentar clientes para campanhas de marketing direcionadas"
        ]
    },
    {
        id: "get_sales_by_channel",
        name: "get_sales_by_channel",
        title: "Sales by channel",
        description: "Retorna faturamento e quantidade de pedidos por canal de venda.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "SalesByChannelResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "ChannelSalesDto[]", 
                    description: "Lista de canais de venda com suas métricas",
                    subfields: [
                        { name: "ChannelName", type: "string", description: "Nome do canal de venda" },
                        { name: "OrdersByChannel", type: "int", description: "Número de pedidos pelo canal" },
                        { name: "GrossSalesByChannel", type: "decimal", description: "Faturamento gerado pelo canal" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_by_channel",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 4
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "ChannelName": "E-commerce",
        "OrdersByChannel": 1250,
        "GrossSalesByChannel": 1875000.00
      },
      {
        "ChannelName": "Loja Física",
        "OrdersByChannel": 890,
        "GrossSalesByChannel": 1563200.00
      },
      {
        "ChannelName": "Telefone",
        "OrdersByChannel": 320,
        "GrossSalesByChannel": 480000.00
      }
    ]
  },
  "id": 4
}`
            }
        },
        useCases: [
            "Comparar eficiência de diferentes canais de venda",
            "Alocar recursos de marketing por canal mais rentável",
            "Identificar oportunidades de expansão em canais subutilizados",
            "Analisar conversão e ticket médio por canal"
        ]
    },
    {
        id: "get_order_status_summary",
        name: "get_order_status_summary",
        title: "Order status summary",
        description: "Retorna um resumo da quantidade de pedidos por status em um intervalo.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "OrderStatusSummaryResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "OrderStatusSummaryDto[]", 
                    description: "Lista de status de pedidos com quantidades",
                    subfields: [
                        { name: "StatusCode", type: "string", description: "Código do status (ex: PENDING, PROCESSING)" },
                        { name: "StatusName", type: "string", description: "Nome descritivo do status" },
                        { name: "Orders", type: "int", description: "Número de pedidos com este status" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_order_status_summary",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 5
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "StatusCode": "DELIVERED",
        "StatusName": "Entregue",
        "Orders": 1250
      },
      {
        "StatusCode": "PROCESSING",
        "StatusName": "Em processamento",
        "Orders": 45
      },
      {
        "StatusCode": "PENDING",
        "StatusName": "Pendente",
        "Orders": 23
      },
      {
        "StatusCode": "CANCELLED",
        "StatusName": "Cancelado",
        "Orders": 15
      }
    ]
  },
  "id": 5
}`
            }
        },
        useCases: [
            "Monitorar eficiência do processo de fulfillment",
            "Identificar gargalos no fluxo de pedidos",
            "Calcular taxa de cancelamento e suas causas",
            "Acompanhar tempo médio de processamento por status"
        ]
    },
    {
        id: "get_recent_orders",
        name: "get_recent_orders",
        title: "Recent orders",
        description: "Retorna pedidos mais recentes, com filtros opcionais por status e codigo do cliente.",
        category: "general",
        authRequired: true,
        parameters: [
            {
                name: "limit",
                type: "int",
                required: true,
                description: "Quantidade maxima de pedidos retornados.",
                example: 50
            },
            {
                name: "statusCode",
                type: "string",
                required: false,
                description: "Codigo de status opcional, por exemplo DELIVERED.",
                example: "DELIVERED"
            },
            {
                name: "customerCode",
                type: "string",
                required: false,
                description: "Codigo do cliente opcional, por exemplo CUS000123.",
                example: "CUS000123"
            }
        ],
        responseStructure: {
            type: "RecentOrdersResultDto",
            fields: [
                { name: "Limit", type: "int", description: "Número máximo de pedidos retornados" },
                { name: "StatusCode", type: "string", description: "Filtro de status aplicado (se houver)" },
                { name: "CustomerCode", type: "string", description: "Filtro de cliente aplicado (se houver)" },
                { 
                    name: "Items", 
                    type: "RecentOrderDto[]", 
                    description: "Lista dos pedidos mais recentes",
                    subfields: [
                        { name: "OrderNumber", type: "string", description: "Número único do pedido" },
                        { name: "CustomerCode", type: "string", description: "Código do cliente" },
                        { name: "CustomerName", type: "string", description: "Nome do cliente" },
                        { name: "StatusCode", type: "string", description: "Status atual do pedido" },
                        { name: "ChannelCode", type: "string", description: "Canal de venda utilizado" },
                        { name: "OrderDate", type: "string", description: "Data do pedido" },
                        { name: "TotalAmount", type: "decimal", description: "Valor total do pedido" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_recent_orders",
    "arguments": {
      "limit": 50,
      "statusCode": "DELIVERED"
    }
  },
  "id": 6
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "Limit": 50,
    "StatusCode": "DELIVERED",
    "CustomerCode": null,
    "Items": [
      {
        "OrderNumber": "ORD20251231001",
        "CustomerCode": "CUS000123",
        "CustomerName": "Empresa ABC Ltda",
        "StatusCode": "DELIVERED",
        "ChannelCode": "ECOMMERCE",
        "OrderDate": "2025-12-31",
        "TotalAmount": 12500.50
      },
      {
        "OrderNumber": "ORD20251230002",
        "CustomerCode": "CUS000456",
        "CustomerName": "Companhia XYZ S.A.",
        "StatusCode": "DELIVERED",
        "ChannelCode": "STORE",
        "OrderDate": "2025-12-30",
        "TotalAmount": 8900.00
      }
    ]
  },
  "id": 6
}`
            }
        },
        useCases: [
            "Monitorar atividade recente de vendas",
            "Acompanhar pedidos específicos de clientes importantes",
            "Analisar padrões de compra em tempo real",
            "Identificar problemas de fulfillment rapidamente"
        ]
    }
];

// Ferramentas de análise de vendedores
const salesRepTools = [
    {
        id: "get_top_sales_reps",
        name: "get_top_sales_reps",
        title: "Top sales representatives",
        description: "Retorna os vendedores com melhor performance por receita, numero de pedidos, ticket medio ou comissao.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            },
            {
                name: "limit",
                type: "int",
                required: true,
                description: "Quantidade maxima de vendedores retornados.",
                example: 10
            },
            {
                name: "sortBy",
                type: "string",
                required: true,
                description: "Ordenacao permitida: revenue, orderCount, averageOrderValue ou commissionAmount.",
                allowedValues: ["revenue", "orderCount", "averageOrderValue", "commissionAmount"],
                example: "revenue"
            }
        ],
        responseStructure: {
            type: "TopSalesRepsResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { name: "Limit", type: "int", description: "Número máximo de vendedores retornados" },
                { name: "SortBy", type: "string", description: "Critério de ordenação utilizado" },
                { 
                    name: "Items", 
                    type: "SalesRepPerformanceDto[]", 
                    description: "Lista dos vendedores com melhor performance",
                    subfields: [
                        { name: "SalesRepCode", type: "string", description: "Código único do vendedor" },
                        { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                        { name: "TotalRevenue", type: "decimal", description: "Receita total gerada" },
                        { name: "OrderCount", type: "int", description: "Número total de pedidos" },
                        { name: "AverageOrderValue", type: "decimal", description: "Ticket médio dos pedidos" },
                        { name: "CommissionAmount", type: "decimal", description: "Valor total de comissão" },
                        { name: "ConversionRate", type: "decimal", description: "Taxa de conversão (%)" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_top_sales_reps",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "limit": 10,
      "sortBy": "revenue"
    }
  },
  "id": 7
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Limit": 10,
    "SortBy": "revenue",
    "Items": [
      {
        "SalesRepCode": "REP001",
        "FullName": "João Silva",
        "TotalRevenue": 1250000.00,
        "OrderCount": 45,
        "AverageOrderValue": 27777.78,
        "CommissionAmount": 125000.00,
        "ConversionRate": 85.5
      },
      {
        "SalesRepCode": "REP002",
        "FullName": "Maria Santos",
        "TotalRevenue": 980000.00,
        "OrderCount": 32,
        "AverageOrderValue": 30625.00,
        "CommissionAmount": 98000.00,
        "ConversionRate": 92.3
      }
    ]
  },
  "id": 7
}`
            }
        },
        useCases: [
            "Identificar top performers para programas de incentivo",
            "Analisar relação entre ticket médio e taxa de conversão",
            "Comparar performance entre diferentes equipes/regiões",
            "Desenvolver benchmarks de performance para a equipe"
        ]
    },
    {
        id: "get_sales_rep_performance_trend",
        name: "get_sales_rep_performance_trend",
        title: "Sales rep performance trend",
        description: "Retorna a evolucao de performance de um vendedor especifico ao longo do tempo.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "salesRepCode",
                type: "string",
                required: true,
                description: "Codigo do vendedor, por exemplo REP001.",
                example: "REP001"
            },
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            },
            {
                name: "groupBy",
                type: "string",
                required: true,
                description: "Agrupamento permitido: day, month ou year.",
                allowedValues: ["day", "month", "year"],
                example: "month"
            }
        ],
        responseStructure: {
            type: "SalesRepPerformanceTrendResultDto",
            fields: [
                { name: "SalesRepCode", type: "string", description: "Código do vendedor analisado" },
                { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { name: "GroupBy", type: "string", description: "Tipo de agrupamento utilizado" },
                { 
                    name: "Points", 
                    type: "SalesRepTrendPointDto[]", 
                    description: "Lista de pontos de performance ao longo do tempo",
                    subfields: [
                        { name: "Period", type: "string", description: "Período (data, mês ou ano)" },
                        { name: "Revenue", type: "decimal", description: "Receita gerada no período" },
                        { name: "Orders", type: "int", description: "Número de pedidos no período" },
                        { name: "Commission", type: "decimal", description: "Comissão calculada no período" },
                        { name: "AverageOrderValue", type: "decimal", description: "Ticket médio no período" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_rep_performance_trend",
    "arguments": {
      "salesRepCode": "REP001",
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "groupBy": "month"
    }
  },
  "id": 8
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "SalesRepCode": "REP001",
    "FullName": "João Silva",
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "GroupBy": "month",
    "Points": [
      {
        "Period": "2025-01",
        "Revenue": 125000.50,
        "Orders": 8,
        "Commission": 12500.05,
        "AverageOrderValue": 15625.06
      },
      {
        "Period": "2025-02",
        "Revenue": 138750.25,
        "Orders": 10,
        "Commission": 13875.03,
        "AverageOrderValue": 13875.03
      }
    ]
  },
  "id": 8
}`
            }
        },
        useCases: [
            "Acompanhar evolução de performance individual",
            "Identificar padrões sazonais na performance",
            "Analisar impacto de treinamentos ou mudanças de estratégia",
            "Detectar tendências de crescimento ou declínio"
        ]
    },
    {
        id: "get_sales_rep_commission_summary",
        name: "get_sales_rep_commission_summary",
        title: "Sales rep commission summary",
        description: "Retorna um resumo de comissoes por vendedor em um periodo.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "SalesRepCommissionResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "SalesRepCommissionSummaryDto[]", 
                    description: "Lista de vendedores com resumo de comissões",
                    subfields: [
                        { name: "SalesRepCode", type: "string", description: "Código único do vendedor" },
                        { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                        { name: "TotalRevenue", type: "decimal", description: "Receita total gerada" },
                        { name: "TotalCommission", type: "decimal", description: "Comissão total calculada" },
                        { name: "CommissionRate", type: "decimal", description: "Taxa de comissão aplicada (%)" },
                        { name: "OrderCount", type: "int", description: "Número total de pedidos" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_rep_commission_summary",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 9
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "SalesRepCode": "REP001",
        "FullName": "João Silva",
        "TotalRevenue": 1250000.00,
        "TotalCommission": 125000.00,
        "CommissionRate": 10.0,
        "OrderCount": 45
      },
      {
        "SalesRepCode": "REP002",
        "FullName": "Maria Santos",
        "TotalRevenue": 980000.00,
        "TotalCommission": 98000.00,
        "CommissionRate": 10.0,
        "OrderCount": 32
      }
    ]
  },
  "id": 9
}`
            }
        },
        useCases: [
            "Calcular custos de comissões por equipe/região",
            "Analisar relação entre receita e comissões pagas",
            "Otimizar estrutura de incentivos e bonificações",
            "Projetar orçamento de comissões para períodos futuros"
        ]
    },
    {
        id: "get_sales_rep_customer_analysis",
        name: "get_sales_rep_customer_analysis",
        title: "Sales rep customer analysis",
        description: "Analise de perfil de clientes por vendedor: novos clientes, clientes recorrentes e taxa de retencao.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "SalesRepCustomerResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "SalesRepCustomerAnalysisDto[]", 
                    description: "Lista de vendedores com análise de clientes",
                    subfields: [
                        { name: "SalesRepCode", type: "string", description: "Código único do vendedor" },
                        { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                        { name: "TotalCustomers", type: "int", description: "Total de clientes únicos" },
                        { name: "NewCustomers", type: "int", description: "Clientes com apenas 1 pedido" },
                        { name: "RepeatCustomers", type: "int", description: "Clientes com 2+ pedidos" },
                        { name: "CustomerRetentionRate", type: "decimal", description: "Taxa de retenção de clientes (%)" },
                        { name: "AverageCustomerValue", type: "decimal", description: "Valor médio por cliente" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_rep_customer_analysis",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 10
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "SalesRepCode": "REP001",
        "FullName": "João Silva",
        "TotalCustomers": 25,
        "NewCustomers": 8,
        "RepeatCustomers": 17,
        "CustomerRetentionRate": 68.0,
        "AverageCustomerValue": 50000.00
      },
      {
        "SalesRepCode": "REP002",
        "FullName": "Maria Santos",
        "TotalCustomers": 18,
        "NewCustomers": 5,
        "RepeatCustomers": 13,
        "CustomerRetentionRate": 72.2,
        "AverageCustomerValue": 54444.44
      }
    ]
  },
  "id": 10
}`
            }
        },
        useCases: [
            "Identificar vendedores com melhor retenção de clientes",
            "Analisar capacidade de aquisição de novos clientes",
            "Desenvolver estratégias de fidelização por vendedor",
            "Comparar valor médio por cliente entre diferentes vendedores"
        ]
    },
    {
        id: "get_sales_rep_comparative_analysis",
        name: "get_sales_rep_comparative_analysis",
        title: "Sales rep comparative analysis",
        description: "Analise comparativa entre vendedores com metricas normalizadas em relacao a media da equipe.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "SalesRepComparativeResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "SalesRepComparativeAnalysisDto[]", 
                    description: "Lista de vendedores com análise comparativa",
                    subfields: [
                        { name: "SalesRepCode", type: "string", description: "Código único do vendedor" },
                        { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                        { 
                            name: "Metrics", 
                            type: "ComparativeAnalysisPointDto[]", 
                            description: "Métricas comparativas vs média da equipe",
                            subfields: [
                                { name: "MetricName", type: "string", description: "Nome da métrica (ex: Revenue, OrderCount)" },
                                { name: "SalesRepValue", type: "decimal", description: "Valor do vendedor" },
                                { name: "TeamAverage", type: "decimal", description: "Média da equipe" },
                                { name: "TeamTopPerformer", type: "decimal", description: "Valor do top performer" },
                                { name: "DifferenceFromAverage", type: "decimal", description: "Diferença em relação à média (%)" }
                            ]
                        }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_rep_comparative_analysis",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 11
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "SalesRepCode": "REP001",
        "FullName": "João Silva",
        "Metrics": [
          {
            "MetricName": "Revenue",
            "SalesRepValue": 1250000.00,
            "TeamAverage": 850000.00,
            "TeamTopPerformer": 1500000.00,
            "DifferenceFromAverage": 47.1
          },
          {
            "MetricName": "OrderCount",
            "SalesRepValue": 45,
            "TeamAverage": 32,
            "TeamTopPerformer": 55,
            "DifferenceFromAverage": 40.6
          }
        ]
      }
    ]
  },
  "id": 11
}`
            }
        },
        useCases: [
            "Identificar gaps de performance em relação à média da equipe",
            "Desenvolver planos de desenvolvimento individual (IDP)",
            "Estabelecer metas realistas baseadas em benchmarks",
            "Analisar distribuição de performance na equipe"
        ]
    },
    {
        id: "get_sales_rep_conversion_analysis",
        name: "get_sales_rep_conversion_analysis",
        title: "Sales rep conversion analysis",
        description: "Analise de metricas de conversao por vendedor: taxa de conversao, ciclo de vendas e win rate.",
        category: "sales-rep",
        authRequired: true,
        parameters: [
            {
                name: "startDate",
                type: "string",
                required: true,
                description: "Data inicial no formato yyyy-MM-dd.",
                example: "2025-01-01"
            },
            {
                name: "endDate",
                type: "string",
                required: true,
                description: "Data final no formato yyyy-MM-dd.",
                example: "2025-12-31"
            }
        ],
        responseStructure: {
            type: "SalesRepConversionResultDto",
            fields: [
                { name: "StartDate", type: "string", description: "Data inicial do período" },
                { name: "EndDate", type: "string", description: "Data final do período" },
                { 
                    name: "Items", 
                    type: "SalesRepConversionMetricsDto[]", 
                    description: "Lista de vendedores com métricas de conversão",
                    subfields: [
                        { name: "SalesRepCode", type: "string", description: "Código único do vendedor" },
                        { name: "FullName", type: "string", description: "Nome completo do vendedor" },
                        { name: "TotalOpportunities", type: "int", description: "Total de oportunidades" },
                        { name: "ConvertedOrders", type: "int", description: "Oportunidades convertidas em pedidos" },
                        { name: "ConversionRate", type: "decimal", description: "Taxa de conversão (%)" },
                        { name: "AverageSalesCycleDays", type: "decimal", description: "Ciclo médio de vendas (dias)" },
                        { name: "WinRate", type: "decimal", description: "Taxa de sucesso em negociações (%)" }
                    ]
                }
            ]
        },
        examples: {
            jsonrpc: {
                request: `{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_sales_rep_conversion_analysis",
    "arguments": {
      "startDate": "2025-01-01",
      "endDate": "2025-12-31"
    }
  },
  "id": 12
}`,
                response: `{
  "jsonrpc": "2.0",
  "result": {
    "StartDate": "2025-01-01",
    "EndDate": "2025-12-31",
    "Items": [
      {
        "SalesRepCode": "REP001",
        "FullName": "João Silva",
        "TotalOpportunities": 60,
        "ConvertedOrders": 45,
        "ConversionRate": 75.0,
        "AverageSalesCycleDays": 15.5,
        "WinRate": 85.0
      },
      {
        "SalesRepCode": "REP002",
        "FullName": "Maria Santos",
        "TotalOpportunities": 45,
        "ConvertedOrders": 32,
        "ConversionRate": 71.1,
        "AverageSalesCycleDays": 12.8,
        "WinRate": 88.9
      }
    ]
  },
  "id": 12
}`
            }
        },
        useCases: [
            "Analisar eficiência do processo de vendas por vendedor",
            "Identificar oportunidades de melhoria no ciclo de vendas",
            "Comparar técnicas de negociação entre vendedores",
            "Otimizar alocação de leads baseada em taxa de conversão"
        ]
    }
];

// Exportar dados para uso na documentação
const allTools = [...mcpTools, ...salesRepTools];
               