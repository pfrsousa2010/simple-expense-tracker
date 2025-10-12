# 💰 Gerenciador de Despesas

Um aplicativo moderno e intuitivo para gerenciar suas receitas e despesas mensais, desenvolvido em Flutter com tema dark.

## 📱 Funcionalidades

### 💵 Receitas
- ✅ Adicionar fontes de renda mensais
- ✅ Reaproveitar fontes de meses anteriores
- ✅ Editar e excluir receitas
- ✅ Visualização do total de receitas do mês

### 💳 Despesas
- ✅ Adicionar despesas com categorias personalizáveis
- ✅ Marcar status: Pago, Agendado ou Débito Automático
- ✅ Definir dia de vencimento
- ✅ Marcar como despesa fixa
- ✅ Copiar despesas fixas para outros meses
- ✅ Notificações 1 dia antes do vencimento
- ✅ Visualização por categorias

### 📊 Categorias
- ✅ 10 categorias pré-definidas
- ✅ Criar categorias personalizadas
- ✅ Definir limite de gastos por categoria
- ✅ Acompanhamento visual do uso do limite (barra de progresso)
- ✅ Alertas visuais quando próximo ou acima do limite
- ✅ Ícones personalizáveis (emojis)

### 📈 Resumo Financeiro
- ✅ Card de saldo com receitas, despesas e saldo total
- ✅ Navegação por meses (anterior/próximo)
- ✅ Visualização de categorias com limite
- ✅ Próximos vencimentos
- ✅ Indicadores visuais de status (pago, agendado, vencido)

## 🎨 Design

- **Tema:** Dark Mode
- **Cores principais:**
  - 🟢 Verde (`#2ECC71`) - Receitas e saldos positivos
  - 🔴 Vermelho (`#E74C3C`) - Despesas e alertas
  - 🔵 Azul (`#3498DB`) - Destaques e ações
  - 🟠 Laranja (`#F39C12`) - Avisos e limites próximos
- **Layout:** Moderno, intuitivo e minimalista
- **Moeda:** Real Brasileiro (R$)
- **Idioma:** Português (pt-BR)

## 🚀 Como executar

### Pré-requisitos
- Flutter SDK (3.9.2 ou superior)
- Dart SDK
- Android Studio ou VS Code com extensões Flutter
- Dispositivo Android ou emulador configurado

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

Android:
```bash
flutter build apk --release
```

iOS:
```bash
flutter build ios --release
```

## 📦 Dependências principais

- **sqflite** - Banco de dados local SQLite
- **provider** - Gerenciamento de estado
- **flutter_local_notifications** - Notificações locais
- **intl** - Formatação de datas e moeda em pt-BR
- **timezone** - Gerenciamento de timezones para notificações

## 🗂️ Estrutura do projeto

```
lib/
├── models/              # Modelos de dados (Categoria, Despesa, FonteRenda)
├── providers/           # Gerenciamento de estado (ExpenseProvider)
├── screens/             # Telas do aplicativo
│   ├── home_screen.dart
│   ├── receitas_screen.dart
│   ├── despesas_screen.dart
│   └── categorias_screen.dart
├── services/            # Serviços (Database, Notificações)
├── utils/               # Utilitários (Tema, Formatadores)
├── widgets/             # Widgets reutilizáveis
└── main.dart            # Ponto de entrada do app
```

## 🔔 Notificações

O app envia notificações locais 1 dia antes do vencimento de despesas cadastradas com data de vencimento. As notificações são agendadas automaticamente quando você:
- Adiciona uma nova despesa com vencimento
- Edita uma despesa existente
- Copia despesas fixas para outro mês

## 💾 Persistência de Dados

Os dados são armazenados localmente no dispositivo usando SQLite. Isso significa:
- ✅ Funciona offline
- ✅ Dados privados (não são enviados para nenhum servidor)
- ✅ Rápido e eficiente
- ❌ Não há sincronização entre dispositivos
- ❌ Dados são perdidos se o app for desinstalado (faça backup se necessário)

## 📝 Categorias Pré-definidas

1. 🍔 Alimentação
2. 🚗 Transporte
3. ⛽ Combustível (com limite padrão de R$ 500)
4. 🏠 Moradia
5. ⚕️ Saúde
6. 📚 Educação
7. 🎮 Lazer
8. 📦 Diversos (com limite padrão de R$ 300)
9. 📄 Contas
10. 👕 Vestuário

## 🎯 Roadmap / Melhorias Futuras

- [ ] Gráficos de gastos por categoria
- [ ] Histórico de meses anteriores
- [ ] Exportar relatórios (PDF/Excel)
- [ ] Backup e restauração de dados
- [ ] Múltiplas contas/carteiras
- [ ] Metas de economia
- [ ] Despesas parceladas
- [ ] Widgets de home screen

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais e uso pessoal.

## 👨‍💻 Desenvolvimento

Desenvolvido com ❤️ usando Flutter
