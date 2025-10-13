# Configuração de Notificações em Background

## Como Funciona

O aplicativo agora envia notificações **automaticamente todos os dias às 9h da manhã**, mesmo quando está fechado, caso haja despesas vencendo hoje ou amanhã.

## Configurações Importantes no Android

Para garantir que as notificações funcionem corretamente mesmo com o app fechado, você precisa configurar algumas permissões no seu dispositivo:

### 1. Desativar Otimização de Bateria

A otimização de bateria pode impedir que o app execute tarefas em background. Siga os passos:

1. Abra as **Configurações** do Android
2. Vá em **Aplicativos** ou **Apps**
3. Encontre **Controle Financeiro** na lista
4. Toque em **Bateria** ou **Uso de bateria**
5. Selecione **Sem restrições** ou **Não otimizar**

#### Marcas Específicas:

**Xiaomi/MIUI:**
- Configurações > Apps > Gerenciar apps > Controle Financeiro
- Ative "Iniciar automaticamente"
- Em "Economizar bateria", selecione "Sem restrições"

**Samsung:**
- Configurações > Apps > Controle Financeiro > Bateria
- Selecione "Sem restrições"
- Configurações > Cuidado do dispositivo > Bateria > Restrições de uso em segundo plano
- Certifique-se de que o app NÃO está na lista

**Huawei:**
- Configurações > Bateria > Inicialização do aplicativo
- Encontre o app e ative "Gerenciar manualmente"
- Ative todas as opções (Inicialização automática, Atividade secundária, Executar em segundo plano)

**OnePlus:**
- Configurações > Bateria > Otimização de bateria
- Toque em "Não otimizar"
- Selecione "Todos os apps" e encontre o Controle Financeiro
- Selecione "Não otimizar"

### 2. Permitir Notificações

1. Configurações > Aplicativos > Controle Financeiro > Notificações
2. Certifique-se de que as notificações estão **ATIVADAS**
3. Verifique se o canal "Vencimentos Diários" está ativado

### 3. Permitir Execução em Background

Algumas marcas têm configurações adicionais:

1. Configurações > Aplicativos > Controle Financeiro
2. Procure por "Dados em segundo plano" ou "Executar em segundo plano"
3. Certifique-se de que está **ATIVADO**

## Testando

Após configurar:

1. Abra o aplicativo uma vez para inicializar as notificações
2. Feche completamente o app
3. As notificações serão enviadas automaticamente às 9h da manhã (próximos dias)

## Observações Importantes

- **Android 12+**: O sistema pode atrasar notificações para economizar bateria. Isso é normal.
- **Primeiro uso**: Após instalar/atualizar, abra o app pelo menos uma vez para ativar as notificações automáticas.
- **Frequência**: As verificações acontecem diariamente, aproximadamente às 9h da manhã.
- **Conteúdo**: Você será notificado apenas se houver contas vencendo hoje ou amanhã.

## Solução de Problemas

**Notificações não aparecem:**
1. Verifique se seguiu todos os passos acima
2. Reinicie o dispositivo
3. Abra o app uma vez para reinicializar o serviço
4. Verifique se há despesas cadastradas para vencer hoje ou amanhã

**Notificações aparecem em horários diferentes:**
- Isso é normal. O Android pode ajustar o horário para otimizar bateria.
- O app tenta executar às 9h, mas pode haver variação de alguns minutos ou até horas dependendo do dispositivo.

## Permissões Necessárias

O app solicita as seguintes permissões:
- **Notificações**: Para exibir alertas
- **Ignorar otimização de bateria**: Para executar em background
- **Alarmes exatos**: Para tentar executar próximo às 9h
- **Iniciar ao ligar**: Para retomar notificações após reiniciar o celular

