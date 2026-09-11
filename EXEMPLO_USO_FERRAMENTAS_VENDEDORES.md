# Exemplo de Uso das Ferramentas de Análise de Vendedores

## Ferramentas Implementadas

### 1. `get_top_sales_reps` - Top Vendedores por Performance
**Descrição:** Retorna os vendedores com melhor performance por receita, número de pedidos, ticket médio ou comissão.

**Parâmetros:**
- `startDate`: Data inicial no formato yyyy-MM-dd
- `endDate`: Data final no formato yyyy-MM-dd  
- `limit`: Quantidade máxima de vendedores retornados
- `sortBy`: Ordenação permitida: `revenue`, `orderCount`, `averageOrderValue` ou `commissionAmount`

**Exemplo de uso:**
```json
{
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "limit": 10,
  "sortBy": "revenue"
}
```

**Métricas retornadas:**
- `SalesRepCode`: Código do vendedor
- `FullName`: Nome completo
- `TotalRevenue`: Receita total gerada
- `OrderCount`: Número de pedidos
- `AverageOrderValue`: Ticket médio
- `CommissionAmount`: Valor da comissão
- `ConversionRate`: Taxa de conversão

### 2. `get_sales_rep_performance_trend` - Evolução de Performance
**Descrição:** Retorna a evolução de performance de um vendedor específico ao longo do tempo.

**Parâmetros:**
- `salesRepCode`: Código do vendedor (ex: REP001)
- `startDate`: Data inicial no formato yyyy-MM-dd
- `endDate`: Data final no formato yyyy-MM-dd
- `groupBy`: Agrupamento permitido: `day`, `month` ou `year`

**Exemplo de uso:**
```json
{
  "salesRepCode": "REP001",
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "groupBy": "month"
}
```

### 3. `get_sales_rep_commission_summary` - Resumo de Comissões
**Descrição:** Retorna um resumo de comissões por vendedor em um período.

**Parâmetros:**
- `startDate`: Data inicial no formato yyyy-MM-dd
- `endDate`: Data final no formato yyyy-MM-dd

**Métricas retornadas:**
- `TotalRevenue`: Receita total por vendedor
- `TotalCommission`: Comissão total calculada
- `CommissionRate`: Taxa de comissão do vendedor
- `OrderCount`: Número de pedidos

### 4. `get_sales_rep_customer_analysis` - Análise de Clientes por Vendedor
**Descrição:** Análise de perfil de clientes por vendedor: novos clientes, clientes recorrentes e taxa de retenção.

**Parâmetros:**
- `startDate`: Data inicial no formato yyyy-MM-dd
- `endDate`: Data final no formato yyyy-MM-dd

**Métricas retornadas:**
- `TotalCustomers`: Total de clientes únicos
- `NewCustomers`: Clientes com apenas 1 pedido
- `RepeatCustomers`: Clientes com 2+ pedidos
- `CustomerRetentionRate`: Taxa de retenção de clientes
- `AverageCustomerValue`: Valor médio por cliente

### 5. `get_sales_rep_comparative_analysis` - Análise Comparativa
**Descrição:** Análise comparativa entre vendedores com métricas normalizadas em relação à média da equipe.

**Parâmetros:**
- `startDate`: Data inicial no formato yyyy-MM-dd
- `endDate`: Data final no formato yyyy-MM-dd

**Métricas comparativas:**
- `Revenue`: Receita vs média da equipe
- `OrderCount`: Número de pedidos vs média
- `AverageOrderValue`: Ticket médio vs média
- `UniqueCustomers`: Clientes únicos vs média

## KPIs Implementados

### 1. **Revenue Metrics (Métricas de Receita)**
- Total Sales Revenue (Receita Total de Vendas)
- Average Deal Size (Ticket Médio)
- Revenue per Sales Rep (Receita por Vendedor)

### 2. **Performance Metrics (Métricas de Performance)**
- Win Rate (Taxa de Conversão)
- Sales Cycle Length (Duração do Ciclo de Vendas)
- Quota Attainment (Atingimento de Meta)

### 3. **Customer Metrics (Métricas de Cliente)**
- Customer Acquisition (Novos Clientes)
- Customer Retention Rate (Taxa de Retenção)
- Average Customer Value (Valor Médio por Cliente)

### 4. **Comparative Metrics (Métricas Comparativas)**
- Performance vs Team Average (Performance vs Média da Equipe)
- Performance vs Top Performer (Performance vs Melhor da Equipe)
- Gap Analysis (Análise de Lacunas)

## Exemplos de Tomada de Decisão Estratégica

### 1. **Identificação de Top Performers**
```json
// Quem são os 5 melhores vendedores por receita?
{
  "tool": "get_top_sales_reps",
  "params": {
    "startDate": "2025-01-01",
    "endDate": "2025-12-31",
    "limit": 5,
    "sortBy": "revenue"
  }
}
```

### 2. **Análise de Evolução de Performance**
```json
// Como o vendedor REP001 evoluiu mês a mês?
{
  "tool": "get_sales_rep_performance_trend",
  "params": {
    "salesRepCode": "REP001",
    "startDate": "2025-01-01",
    "endDate": "2025-12-31",
    "groupBy": "month"
  }
}
```

### 3. **Otimização de Comissões**
```json
// Qual o impacto das comissões por vendedor?
{
  "tool": "get_sales_rep_commission_summary",
  "params": {
    "startDate": "2025-01-01",
    "endDate": "2025-12-31"
  }
}
```

### 4. **Estratégia de Retenção de Clientes**
```json
// Quais vendedores têm melhor retenção de clientes?
{
  "tool": "get_sales_rep_customer_analysis",
  "params": {
    "startDate": "2025-01-01",
    "endDate": "2025-12-31"
  }
}
```

### 5. **Benchmarking e Desenvolvimento de Equipe**
```json
// Como cada vendedor se compara com a média da equipe?
{
  "tool": "get_sales_rep_comparative_analysis",
  "params": {
    "startDate": "2025-01-01",
    "endDate": "2025-12-31"
  }
}
```

## Benefícios para Gestores e Coordenadores

### 1. **Tomada de Decisão Baseada em Dados**
- Identificar padrões de performance
- Detectar oportunidades de melhoria
- Alocar recursos de forma eficiente

### 2. **Otimização de Comissões**
- Analisar relação custo-benefício das comissões
- Identificar vendedores com melhor ROI
- Ajustar políticas de incentivo

### 3. **Desenvolvimento de Equipe**
- Identificar necessidades de treinamento
- Criar programas de mentoria
- Estabelecer metas realistas

### 4. **Estratégia Comercial**
- Focar em produtos/segmentos mais rentáveis
- Desenvolver estratégias de retenção
- Otimizar alocação de territórios

## Próximos Passos

1. **Testar as ferramentas** com dados reais do banco
2. **Coletar feedback** dos usuários (gestores/coordenadores)
3. **Refinar métricas** com base nas necessidades do negócio
4. **Adicionar visualizações** para melhor apresentação dos dados
5. **Implementar alertas** para métricas críticas

## Considerações Técnicas

- Todas as ferramentas usam **autenticação** (`[Authorize]`)
- **Validações robustas** de parâmetros de entrada
- **Otimização de queries** SQL para performance
- **Tratamento de erros** adequado
- **Compatibilidade** com o sistema MCP existente