# Децентрализованная система голосования со стейкингом и NFT

Проект реализует систему голосования, где пользователи могут стейкать токены для получения голосующей силы. Результаты голосований финализируются в виде NFT с метаданными.

## Основные компоненты

Система состоит из трёх смарт-контрактов:

1. **Staking (стейкинг)** - Управление стейкингом токенов
2. **VotingSystem (голосование)** - Организация голосований
3. **VoteResultNFT (NFT)** - Чеканка NFT с результатами

## Адреса в сети Sepolia

```solidity
// Основные контракты
address constant STAKING_ADDRESS = 0xdcd58c6028184298aA374eFC46898a5f5cd87D1c;
address constant VOTING_ADDRESS = 0xabDFF56ce26536d73F40D46fE80B9e1C88b13e30;
address constant NFT_ADDRESS = 0xEBc78D16D34626263d46cB443e19c86b0aB7D69D;

// Вспомогательные адреса
address constant ERC20_ADDRESS = 0xD3835FE9807DAecc7dEBC53795E7170844684CeF; // ERC20  VegaVoteToken токен
address constant ADMIN = 0xC4ce21C3FBA666C4EE33346b88932a7BBB4c65e2; // Администратор
