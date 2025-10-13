# 💰 Controle Financeiro

Um aplicativo moderno e intuitivo para gerenciar suas receitas e despesas mensais, desenvolvido em Flutter com tema dark elegante.

## 📱 Funcionalidades

### 💵 Receitas
- ✅ Adicionar fontes de renda mensais
- ✅ Reaproveitar fontes de meses anteriores (autocomplete)
- ✅ Editar e excluir receitas
- ✅ Visualização do total de receitas do mês
- ✅ Pull-to-refresh para atualizar dados

### 💳 Despesas
- ✅ Adicionar despesas com categorias personalizáveis
- ✅ Marcar status: Pago, Agendado, Débito Automático ou A Pagar
- ✅ Definir dia de vencimento (1-31)
- ✅ Marcar como despesa fixa para replicação futura
- ✅ Copiar despesas fixas para outros meses
- ✅ Editar e excluir despesas com swipe gesture
- ✅ Visualização agrupada por categorias
- ✅ Filtragem por status de pagamento

### 📊 Categorias
- ✅ 10 categorias pré-definidas com ícones emoji
- ✅ Criar categorias personalizadas ilimitadas
- ✅ Definir limite de gastos por categoria
- ✅ Acompanhamento visual do uso do limite (barra de progresso)
- ✅ Alertas visuais quando próximo ou acima do limite
- ✅ Seletor de ícones com biblioteca completa de emojis
- ✅ Proteção contra exclusão de categorias padrão

### 📈 Resumo Financeiro
- ✅ Card de saldo com receitas, despesas e saldo total
- ✅ Navegação por meses (anterior/próximo)
- ✅ Visualização de categorias com limite na home
- ✅ **Vencimentos do dia** - card com contador de despesas vencendo hoje
- ✅ **Próximos vencimentos** - card com contador de despesas a vencer no mês
- ✅ Indicadores visuais de status (pago, agendado, a pagar, débito automático)
- ✅ Códigos de cor por urgência de vencimento

### 🔔 Notificações
- ✅ **Notificações em Background** - Funciona mesmo com o app fechado
- ✅ **Notificações diárias automáticas às 09:00** - Verifica despesas vencendo hoje e amanhã
- ✅ **Execução independente** - Não precisa abrir o app diariamente
- ✅ Sistema de tarefas periódicas com WorkManager
- ✅ Solicitação de permissões no primeiro uso
- ✅ Compatível com otimização de bateria do Android

## 🎨 Design

- **Tema:** Dark Mode com Material Design 3
- **Cores principais:**
  - 🟢 Verde (`#2ECC71`) - Receitas e saldos positivos
  - 🔴 Vermelho (`#E74C3C`) - Despesas e alertas
  - 🔵 Azul (`#3498DB`) - Destaques e ações
  - 🟠 Laranja/Amarelo (`#F39C12`) - Avisos e limites próximos
  - 🟠 Laranja Vibrante (`#FF6B35`) - Vencimentos de hoje
- **Paleta de fundo:**
  - Background: `#121212`
  - Surface: `#1E1E1E`
  - Cards: `#2C2C2C`
- **Layout:** Moderno, intuitivo e minimalista com glassmorphism e gradientes sutis
- **Moeda:** Real Brasileiro (R$)
- **Idioma:** Português (pt-BR)
- **Ícone do app:** Customizado com adaptive icons

## 🚀 Como executar

### Pré-requisitos
- Flutter SDK (3.9.2 ou superior)
- Dart SDK (^3.9.2)
- Android Studio ou VS Code com extensões Flutter
- Dispositivo físico ou emulador (Android/iOS/Windows/Linux/macOS)

### Instalação

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd simple_expense_tracker
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Execute o aplicativo:
```bash
flutter run
```

### Build para produção

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

**macOS:**
```bash
flutter build macos --release
```

### Gerar ícones do app
```bash
flutter pub run flutter_launcher_icons
```

## 📦 Dependências principais

- **sqflite** (^2.3.0) - Banco de dados local SQLite
- **provider** (^6.1.1) - Gerenciamento de estado
- **flutter_local_notifications** (^17.0.0) - Notificações locais
- **workmanager** (^0.9.0) - Tarefas em background/notificações periódicas
- **intl** (^0.20.2) - Formatação de datas e moeda em pt-BR
- **timezone** (^0.9.2) - Gerenciamento de timezones para notificações
- **flutter_iconpicker** (^3.2.4) - Seletor de ícones emoji para categorias
- **path_provider** (^2.1.1) - Acesso a diretórios do sistema
- **cupertino_icons** (^1.0.8) - Ícones iOS style

## 🗂️ Estrutura do projeto

```
lib/
├── models/              # Modelos de dados
│   ├── categoria.dart
│   ├── despesa.dart
│   └── fonte_renda.dart
├── providers/           # Gerenciamento de estado
│   └── expense_provider.dart
├── screens/             # Telas do aplicativo
│   ├── home_screen.dart                    # Tela principal
│   ├── receitas_screen.dart                # Gerenciamento de receitas
│   ├── despesas_screen.dart                # Gerenciamento de despesas
│   ├── categorias_screen.dart              # Gerenciamento de categorias
│   ├── vencendo_hoje_screen.dart           # Despesas vencendo hoje
│   ├── proximos_vencimentos_screen.dart    # Próximos vencimentos
│   └── copiar_despesas_fixas_screen.dart   # Copiar despesas fixas
├── services/            # Serviços
│   ├── database_service.dart               # SQLite
│   └── notification_service.dart           # Notificações
├── utils/               # Utilitários
│   ├── app_theme.dart                      # Tema dark
│   └── formatters.dart                     # Formatadores pt-BR
├── widgets/             # Widgets reutilizáveis
│   ├── saldo_card.dart
│   ├── categoria_gastos_card.dart
│   ├── despesa_item.dart
│   ├── dia_vencimento_selector.dart
│   └── dia_vencimento_selector_simples.dart
└── main.dart            # Ponto de entrada do app
```

## 🔔 Sistema de Notificações

O aplicativo possui um sistema robusto de notificações em background que funciona **mesmo com o app fechado**:

### Notificações Diárias Automáticas
- **Horário:** Todos os dias às 09:00 da manhã
- **Conteúdo:** 
  - Despesas vencendo **hoje** (se houver)
  - Despesas vencendo **amanhã** (se houver)
- **Tecnologia:** WorkManager para execução em background
- **Funcionamento:** Completamente automático, não precisa abrir o app

### Como funciona
1. **Primeira vez:** Ao abrir o app, solicita permissões necessárias
2. **Agendamento:** Task periódica é configurada automaticamente
3. **Execução diária:** Todos os dias às ~09:00, o sistema:
   - Verifica despesas vencendo hoje e amanhã
   - Envia notificações apenas se houver despesas pendentes
   - Funciona mesmo com o app completamente fechado
4. **Inteligente:** Só notifica se existirem contas a pagar

### ⚙️ Configuração Importante

Para garantir que as notificações funcionem em background:

1. **Desative a otimização de bateria** para este app
2. **Permita execução em segundo plano**
3. **Ative notificações** nas configurações do sistema

> 📖 **Veja o arquivo [NOTIFICACOES.md](NOTIFICACOES.md)** para instruções detalhadas sobre como configurar seu dispositivo Android (especialmente Xiaomi, Samsung, Huawei, OnePlus)

### Limitações do Android
- Android 12+ pode atrasar notificações para economizar bateria
- Fabricantes como Xiaomi/Huawei têm otimizações agressivas que podem bloquear
- O horário de 09:00 é aproximado, pode variar alguns minutos/horas

## 💾 Persistência de Dados

Os dados são armazenados localmente no dispositivo usando **SQLite** (via sqflite):

### Vantagens
- ✅ Funciona 100% offline
- ✅ Dados totalmente privados (não são enviados para nenhum servidor)
- ✅ Rápido e eficiente
- ✅ Estrutura relacional com integridade referencial

### Limitações
- ❌ Não há sincronização entre dispositivos
- ❌ Dados são perdidos se o app for desinstalado
- ❌ Não há backup automático em nuvem

### Estrutura do Banco de Dados
- **categorias** - ID, nome, ícone, limite de gasto, flag de padrão
- **fontes_renda** - ID, nome, valor, mês, ano
- **despesas** - ID, descrição, valor, categoria, mês, ano, dia vencimento, status, flag de fixa, data de criação

## 📝 Categorias Pré-definidas

Ao instalar o app pela primeira vez, as seguintes categorias são criadas automaticamente:

1. 🍔 **Alimentação**
2. 🚗 **Transporte**
3. ⛽ **Combustível** (com limite padrão de R$ 500,00)
4. 🏠 **Moradia**
5. ⚕️ **Saúde**
6. 📚 **Educação**
7. 🎮 **Lazer**
8. 📦 **Diversos** (com limite padrão de R$ 300,00)
9. 📄 **Contas**
10. 👕 **Vestuário**

> **Nota:** As categorias padrão não podem ser excluídas, mas podem ter seus limites editados. Você pode criar quantas categorias personalizadas desejar.

## 🎯 Roadmap / Melhorias Futuras

### Funcionalidades Planejadas
- [ ] 📊 Gráficos interativos de gastos por categoria
- [ ] 📅 Visualização de histórico de meses anteriores
- [ ] 📄 Exportar relatórios (PDF/Excel/CSV)
- [ ] ☁️ Backup e restauração de dados (Google Drive/iCloud)
- [ ] 💼 Múltiplas contas/carteiras
- [ ] 🎯 Metas de economia mensal
- [ ] 💳 Despesas parceladas com controle de parcelas
- [ ] 📱 Widgets de home screen (Android/iOS)
- [ ] 🔍 Busca e filtros avançados
- [ ] 🏷️ Tags personalizadas para despesas
- [ ] 📸 Anexar fotos de comprovantes
- [ ] 🌐 Modo claro (Light Theme)
- [ ] 🔐 Autenticação biométrica
- [ ] 💱 Suporte a múltiplas moedas

## 💡 Dicas de Uso

### Para melhor experiência:
1. **Configure categorias com limites** - Ajuda a controlar gastos específicos
2. **Marque despesas recorrentes como fixas** - Facilita a cópia para meses futuros
3. **Defina vencimentos** - Receba notificações e não perca prazos
4. **Use o pull-to-refresh** - Para atualizar os dados em todas as telas
5. **Ative as notificações** - Seja lembrado das despesas no dia do vencimento
6. **Dê nomes claros às receitas** - O autocomplete vai facilitar a reutilização

### Atalhos e Gestos:
- **Swipe** para editar ou excluir despesas
- **Pull-to-refresh** para recarregar dados
- **Toque** nos cards de vencimento para ver detalhes
- **Navegue** entre meses usando as setas na tela principal

## 🐛 Problemas Conhecidos

- **Notificações em background:** Alguns fabricantes (Xiaomi, Huawei, OnePlus) têm otimização agressiva de bateria que pode bloquear notificações. Consulte o arquivo [NOTIFICACOES.md](NOTIFICACOES.md) para configurar corretamente
- Em alguns casos, o banco de dados precisa ser reinicializado após updates
- O horário exato das notificações (09:00) pode variar dependendo do dispositivo e otimizações do sistema

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais e uso pessoal.

## 👨‍💻 Desenvolvimento

Desenvolvido com ❤️ usando Flutter

### Tecnologias Utilizadas:
- **Framework:** Flutter 3.9.2+
- **Linguagem:** Dart
- **Arquitetura:** Provider Pattern (State Management)
- **Banco de Dados:** SQLite
- **Design:** Material Design 3 Dark Theme
- **Localização:** pt-BR (Português do Brasil)

---

**Versão:** 1.0.0+1
