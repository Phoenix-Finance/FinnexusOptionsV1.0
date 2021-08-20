pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/ReentrancyGuard.sol";
import "../PhoenixModules/modules/whiteListAddress.sol";
import "../PhoenixModules/proxyModules/Halt.sol";
import "../PhoenixModules/proxyModules/ImputRange.sol";
import "../PhoenixModules/proxyModules/AddressPermission.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../PhoenixModules/PPTCoin/IPPTCoin.sol";
import "../PhoenixModules/ERC20/IERC20.sol";

import "../CollateralPool/ICollateralPool.sol";
import "../OptionsPool/IOptionsPool.sol";
import "../interfaces/IOptionsPrice.sol";
/**
 * @title collateral calculate module
 * @dev A smart-contract which has operations of collateral and methods of calculate collateral occupation.
 *
 */
contract ManagerData is versionUpdater,Halt,ReentrancyGuard,ImputRange,AddressPermission,
                ImportOracle {
    using whiteListAddress for address[];
    uint256 constant internal currentVersion = 4;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 constant internal allPermission = 0xffffffff;
    uint256 constant internal allowBuyOptions = 1;
    uint256 constant internal allowSellOptions = 1<<1;
    uint256 constant internal allowExerciseOptions = 1<<2;
    uint256 constant internal allowAddCollateral = 1<<3;
    uint256 constant internal allowRedeemCollateral = 1<<4;

    // The eligible adress list
    address[] internal whiteList;
    IOptionsPool public optionsPool;
    IOptionsPrice public optionsPrice;
    ICollateralPool public collateralPool;
    IPPTCoin public pptCoin;
    // The minimum collateral rate for options. This value is thousandths.
    mapping (address=>uint256) collateralRate;
//    uint256 private collateralRate = 5000;
    /**
     * @dev Emitted when `from` added `amount` collateral and minted `tokenAmount` FPTCoin.
     */
    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);
    /**
     * @dev Emitted when `from` redeemed `allRedeem` collateral.
     */
    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);
    event DebugEvent(uint256 id,uint256 value1,uint256 value2);
        /**
    * @dev input price valid range rate, thousandths.
    * the input price must greater than current price * minPriceRate /1000
    *       and less  than current price * maxPriceRate /1000 
    * maxPriceRate is the maximum limit of the price valid range rate
    * maxPriceRate is the minimum limit of the price valid range rage
    */   
    uint256 public maxPriceRate;
    uint256 public minPriceRate;
    /**
     * @dev Emitted when `from` buy `optionAmount` option and create new option.
     * @param from user's account
     * @param settlement user's input settlement paid for buy new option.
     * @param optionPrice option's paid price
     * @param settlementAmount settement cost
     * @param optionAmount mint option token amount.
     */  
    event BuyOption(address indexed from,address indexed settlement,uint256 optionPrice,uint256 settlementAmount,uint256 optionAmount);
    /**
     * @dev Emitted when `from` sell `amount` option whose id is `optionId` and received sellValue,priced in usd.
     */  
    event SellOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    /**
     * @dev Emitted when `from` exercise `amount` option whose id is `optionId` and received sellValue,priced in usd.
     */  
    event ExerciseOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
}
