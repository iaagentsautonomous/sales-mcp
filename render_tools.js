// Script para renderizar as ferramentas na documentação HTML
document.addEventListener('DOMContentLoaded', function() {
    const toolsContainer = document.getElementById('tools-documentation');
    if (!toolsContainer) return;

    // Combinar todas as ferramentas
    const allTools = [...mcpTools, ...salesRepTools];
    
    // Renderizar ferramentas de análise geral
    const generalTools = allTools.filter(tool => tool.category === 'general');
    const salesRepToolsList = allTools.filter(tool => tool.category === 'sales-rep');
    
    // Adicionar seção de análise geral
    toolsContainer.innerHTML = `
        <section id="general-analysis" class="section">
            <div class="section-header">
                <h2>Análise Geral de Vendas</h2>
                <p class="description">
                    6 ferramentas para análise abrangente de dados de vendas, incluindo faturamento, produtos, clientes e canais.
                </p>
            </div>
            ${generalTools.map(tool => renderToolCard(tool)).join('')}
        </section>
        
        <section id="sales-rep-analysis" class="section">
            <div class="section-header">
                <h2>Análise de Vendedores</h2>
                <p class="description">
                    7 ferramentas especializadas para análise de performance, comissões, conversão e desenvolvimento de equipes de vendas.

                </p>
            </div>
            ${salesRepToolsList.map(tool => renderToolCard(tool)).join('')}
        </section>
    `;
    
    // Adicionar IDs às seções das ferramentas individualmente
    setTimeout(() => {
        allTools.forEach(tool => {
            const element = document.getElementById(tool.id);
            if (element) {
                element.scrollIntoView = function() {
                    window.scrollTo({
                        top: this.offsetTop - 20,
                        behavior: 'smooth'
                    });
                };
            }
        });
    }, 100);
});

function renderToolCard(tool) {
    return `
        <div id="${tool.id}" class="tool-card">
            <div class="tool-header">
                <div class="tool-title">
                    <h3>${tool.title}</h3>
                    <div class="tool-name">${tool.name}</div>
                </div>
                <div>
                    ${tool.authRequired ? '<span class="auth-badge">Requer autenticação</span>' : ''}
                    <span class="badge ${tool.category === 'general' ? 'badge-general' : 'badge-sales-rep'}">
                        ${tool.category === 'general' ? 'Análise Geral' : 'Análise de Vendedores'}
                    </span>
                </div>
            </div>
            
            <p class="tool-description">${tool.description}</p>
            
            <!-- Parâmetros -->
            <div class="parameters-section">
                <h4 class="section-title">Parâmetros</h4>
                <table>
                    <thead>
                        <tr>
                            <th>Parâmetro</th>
                            <th>Tipo</th>
                            <th>Obrigatório</th>
                            <th>Descrição</th>
                            <th>Valores Permitidos</th>
                            <th>Exemplo</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${tool.parameters.map(param => `
                            <tr>
                                <td><span class="param-name">${param.name}</span></td>
                                <td><span class="param-type">${param.type}</span></td>
                                <td>${param.required ? '<span class="required">Obrigatório</span>' : '<span class="optional">Opcional</span>'}</td>
                                <td>${param.description}</td>
                                <td>${param.allowedValues ? param.allowedValues.join(', ') : 'Qualquer valor válido'}</td>
                                <td><code>${param.example || 'N/A'}</code></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
            
            <!-- Exemplos de Uso -->
            <div class="code-section">
                <h4 class="section-title">Exemplos de Uso</h4>
                <div class="code-tabs">
                    <button class="code-tab active" onclick="switchToolTab('${tool.id}-jsonrpc')">JSON-RPC</button>
                    ${tool.examples.cline ? `<button class="code-tab" onclick="switchToolTab('${tool.id}-cline')">Cline</button>` : ''}
                    <button class="code-tab" onclick="switchToolTab('${tool.id}-response')">Resposta</button>
                </div>
                
                <div id="${tool.id}-jsonrpc" class="code-block" style="display: block;">
                    <div class="code-header">
                        <span class="code-language">JSON</span>
                        <button class="copy-btn" onclick="copyCode('${tool.id}-jsonrpc')">Copiar</button>
                    </div>
                    <div class="code-content">
                        <pre><code>${tool.examples.jsonrpc.request}</code></pre>
                    </div>
                </div>
                
                ${tool.examples.cline ? `
                <div id="${tool.id}-cline" class="code-block" style="display: none;">
                    <div class="code-header">
                        <span class="code-language">JSON</span>
                        <button class="copy-btn" onclick="copyCode('${tool.id}-cline')">Copiar</button>
                    </div>
                    <div class="code-content">
                        <pre><code>${tool.examples.cline}</code></pre>
                    </div>
                </div>
                ` : ''}
                
                <div id="${tool.id}-response" class="code-block" style="display: none;">
                    <div class="code-header">
                        <span class="code-language">JSON</span>
                        <button class="copy-btn" onclick="copyCode('${tool.id}-response')">Copiar</button>
                    </div>
                    <div class="code-content">
                        <pre><code>${tool.examples.jsonrpc.response}</code></pre>
                    </div>
                </div>
            </div>
            
            <!-- Estrutura da Resposta -->
            <div class="response-structure">
                <h4 class="section-title">Estrutura da Resposta</h4>
                <p><strong>Tipo:</strong> <code>${tool.responseStructure.type}</code></p>
                ${tool.responseStructure.fields.map(field => `
                    <div class="response-field">
                        <span class="field-name">${field.name}</span>
                        <span class="field-type">${field.type}</span>
                        <p class="field-description">${field.description}</p>
                        ${field.subfields ? `
                            <div style="margin-left: 1.5rem; margin-top: 0.5rem;">
                                ${field.subfields.map(subfield => `
                                    <div style="margin-bottom: 0.5rem;">
                                        <span class="field-name" style="font-size: 0.875rem;">${subfield.name}</span>
                                        <span class="field-type" style="font-size: 0.75rem;">${subfield.type}</span>
                                        <p class="field-description" style="font-size: 0.8125rem;">${subfield.description}</p>
                                    </div>
                                `).join('')}
                            </div>
                        ` : ''}
                    </div>
                `).join('')}
            </div>
            
            <!-- Casos de Uso -->
            <div class="use-cases">
                <h4 class="section-title">Casos de Uso</h4>
                ${tool.useCases.map(useCase => `
                    <div class="use-case">
                        <h4>${useCase}</h4>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

// Função para alternar entre abas de ferramentas
function switchToolTab(tabId) {
    const toolId = tabId.split('-').slice(0, -1).join('-');
    const tabType = tabId.split('-').pop();
    
    // Esconder todas as abas desta ferramenta
    document.querySelectorAll(`[id^="${toolId}-"]`).forEach(block => {
        block.style.display = 'none';
    });
    
    // Remover classe active de todas as abas desta ferramenta
    const card = document.getElementById(toolId);
    if (card) {
        card.querySelectorAll('.code-tab').forEach(tab => {
            tab.classList.remove('active');
        });
    }
    
    // Mostrar aba selecionada
    const targetTab = document.getElementById(tabId);
    if (targetTab) {
        targetTab.style.display = 'block';
    }
    
    // Adicionar classe active à aba clicada
    event.target.classList.add('active');
}

// Função para copiar código (sobrescreve a função global)
window.copyCode = function(blockId) {
    const codeBlock = document.getElementById(blockId);
    if (!codeBlock) return;
    
    const code = codeBlock.querySelector('code').textContent;
    
    navigator.clipboard.writeText(code).then(() => {
        const btn = event.target;
        const originalText = btn.textContent;
        btn.textContent = 'Copiado!';
        btn.style.background = '#10b981';
        
        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.background = '';
        }, 2000);
    });
};

// Função para alternar entre abas (sobrescreve a função global)
window.switchTab = function(tabId) {
    // Hide all code blocks
    document.querySelectorAll('.code-block').forEach(block => {
        block.style.display = 'none';
    });
    
    // Remove active class from all tabs
    document.querySelectorAll('.code-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Show selected code block
    document.getElementById(tabId).style.display = 'block';
    
    // Add active class to clicked tab
    event.target.classList.add('active');
};