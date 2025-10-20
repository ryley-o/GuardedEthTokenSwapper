/**
 * GuardedEthTokenSwapper - Production Token Configuration
 * 
 * This file defines the 13 production-ready ETH trading pairs that have been
 * optimized and validated for 5% oracle tolerance at block 23620206.
 * 
 * All tokens use Chainlink TOKEN/ETH price feeds and optimal Uniswap V3 fee tiers.
 */

export interface TokenPair {
  symbol: string;
  pair: string;
  chainlinkFeed: string;
  uniswapFeeTier: number; // basis points (500 = 0.05%, 3000 = 0.30%, 10000 = 1.00%)
  description: string;
}

export const productionPairs: TokenPair[] = [
  // Optimized Fee Tiers (1.00%) - Higher liquidity pools
  {
    symbol: "1INCH",
    pair: "1INCH/ETH",
    chainlinkFeed: "0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8",
    uniswapFeeTier: 10000,
    description: "1inch Network - DEX aggregator token"
  },
  {
    symbol: "SHIB",
    pair: "SHIB/ETH", 
    chainlinkFeed: "0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61",
    uniswapFeeTier: 10000,
    description: "Shiba Inu - Volatile memecoin"
  },

  // Major DeFi Tokens (0.30%) - Standard fee tier
  {
    symbol: "AAVE",
    pair: "AAVE/ETH",
    chainlinkFeed: "0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012", 
    uniswapFeeTier: 3000,
    description: "Aave Protocol - Lending platform"
  },
  {
    symbol: "APE",
    pair: "APE/ETH",
    chainlinkFeed: "0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18",
    uniswapFeeTier: 3000,
    description: "ApeCoin - NFT ecosystem token"
  },
  {
    symbol: "BAT",
    pair: "BAT/ETH",
    chainlinkFeed: "0x0d16d4528239e9ee52fa531af613AcdB23D88c94",
    uniswapFeeTier: 3000,
    description: "Basic Attention Token - Browser rewards"
  },
  {
    symbol: "COMP",
    pair: "COMP/ETH",
    chainlinkFeed: "0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699",
    uniswapFeeTier: 3000,
    description: "Compound - Lending protocol governance"
  },
  {
    symbol: "CRV",
    pair: "CRV/ETH",
    chainlinkFeed: "0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e",
    uniswapFeeTier: 3000,
    description: "Curve DAO - DEX for stablecoins"
  },
  {
    symbol: "LDO",
    pair: "LDO/ETH",
    chainlinkFeed: "0x4e844125952D32AcdF339BE976c98E22F6F318dB",
    uniswapFeeTier: 3000,
    description: "Lido DAO - Liquid staking governance"
  },
  {
    symbol: "LINK",
    pair: "LINK/ETH",
    chainlinkFeed: "0xDC530D9457755926550b59e8ECcdaE7624181557",
    uniswapFeeTier: 3000,
    description: "Chainlink - Oracle network"
  },
  {
    symbol: "MKR",
    pair: "MKR/ETH",
    chainlinkFeed: "0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2",
    uniswapFeeTier: 3000,
    description: "Maker - DAI stablecoin governance"
  },
  {
    symbol: "UNI",
    pair: "UNI/ETH",
    chainlinkFeed: "0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e",
    uniswapFeeTier: 3000,
    description: "Uniswap - DEX governance token"
  },
  {
    symbol: "ZRX",
    pair: "ZRX/ETH",
    chainlinkFeed: "0x2Da4983a622a8498bb1a21FaE9D8F6C664939962",
    uniswapFeeTier: 3000,
    description: "0x Protocol - DEX infrastructure"
  },

  // Stablecoin (0.05%) - Low volatility, high volume
  {
    symbol: "USDT",
    pair: "USDT/ETH",
    chainlinkFeed: "0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46",
    uniswapFeeTier: 500,
    description: "Tether USD - Leading stablecoin"
  }
];

// Legacy export for backwards compatibility
export const pairs = productionPairs.map(p => p.pair);

// Summary statistics
export const pairStats = {
  totalPairs: productionPairs.length,
  feeDistribution: {
    "0.05%": productionPairs.filter(p => p.uniswapFeeTier === 500).length,
    "0.30%": productionPairs.filter(p => p.uniswapFeeTier === 3000).length, 
    "1.00%": productionPairs.filter(p => p.uniswapFeeTier === 10000).length
  },
  optimizedForBlock: 23620206,
  oracleValidationTolerance: "5%"
};