# Децентрализованная система голосования со стейкингом и NFT

Проект реализует систему голосования, где пользователи могут стейкать токены для получения голосующей силы. Результаты голосований финализируются в виде NFT с метаданными.  
Особенности реализации прописаны комментариями в коде + демонстрируются в тестах (первый набор тестов Voting.t.sol).  

## Основные компоненты

Система состоит из трёх смарт-контрактов:

1. **Staking (стейкинг)** - Управление стейкингом токенов
2. **VotingSystem (голосование)** - Организация голосований
3. **VoteResultNFT (NFT)** - Выпуск NFT с результатами

## Адреса в сети Sepolia

```solidity
// Основные контракты
address constant STAKING_ADDRESS = 0x95f853852FacBdf4a6F34D63bE6dbF864A5Ef695 ;
address constant VOTING_ADDRESS = 0x45B5904B2180261e050B83a293d9f4D2194083b8;
address constant NFT_ADDRESS = 0xEf947b86CF445d32D5c67d5019fada1BCA7a6af5;

// Вспомогательные адреса
address constant ERC20_ADDRESS = 0xD3835FE9807DAecc7dEBC53795E7170844684CeF; // ERC20  VegaVoteToken токен
address constant ADMIN = 0xC4ce21C3FBA666C4EE33346b88932a7BBB4c65e2; // Администратор, 
                                                                     //его приватный ключ (если нужен) можно узнать у @white_mi98
```

## для тестирования в сети Sepolia :   
forge test --match-contract LiveNetworkTest   --fork-url $RPC_URL   -vvvv  

## Заметки
1. .env содержит: ADDRESS="0xC4ce21C3FBA666C4EE33346b88932a7BBB4c65e2" - Админ  
ERC20_ADDRESS="0xD3835FE9807DAecc7dEBC53795E7170844684CeF" -  VegaVoteToken  
PRIVATE_KEY,RPC_URL,ETHERSCAN_API_KEY (not published)
2. Реализован свой токен для первых тестов, тоже размещён в данном гитхабе, на Sepolia не размещён. Написан интерфейс для работы с ERC20 токеном с возможностью минтить токен.