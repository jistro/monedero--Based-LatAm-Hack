import { Box, Button, Card, Spinner } from "@radix-ui/themes";
import styles from "../styles/Deposits.module.css";
import { useState } from "react";
import { readContract, writeContract, getAccount } from "@wagmi/core";
import { config } from "../wagmi";
import { erc20Abi } from "viem";
import Staking from "../../abis/Staking.json";

export const Transfer = () => {
  const StakingAddress: `0x${string}` =
    "0x8155bFe2bdcDD09bD565D31067646CA3790Bb77a";
  const USDCAddress: `0x${string}` =
    "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  const mUSDAddress: `0x${string}` =
    "0x1932d99C5115a283D9f0919C9e6FE56b2060063B";

  const [flagTypeAction, setFlagTypeAction] = useState<string>("nothing");

  const [amountUSD, setAmountUSD] = useState<number>(0);

  const transfer = async () => {
    const amountToDeposit = (
      document.getElementById("amountToDeposit") as HTMLInputElement
    ).value;
    const amountToDepositWei = BigInt(Number(amountToDeposit) * 10 ** 6);
    setFlagTypeAction("wait");
    writeContract(config, {
      abi: Staking.abi,
      address: mUSDAddress,
      functionName: "transfer",
      args: [USDCAddress, amountToDepositWei],
    })
      .then(() => {
        setFlagTypeAction("nothing");
      })
      .catch(() => {
        setFlagTypeAction("nothing");
      });
  };

  return (
    <main className={styles.main}>
      <Box maxWidth="100%">
        <Card>
          <div className={styles.cardContainer}>
            <Box>
              <Card>
                <div className={styles.cardData}>
                  <h3>Cantidad: </h3>{" "}
                  <div className={styles.cardData__containerTokenInfo}>
                    <p>$</p>
                    <input
                      type="number"
                      placeholder="0"
                      id="amountToDeposit"
                      onChange={(e) => setAmountUSD(Number(e.target.value))}
                    />
                  </div>
                </div>
              </Card>
            </Box>
            <Box>
              <Card asChild>
                <div className={styles.cardData}>
                  <h3>Direccion: </h3>
                  <div className={styles.cardData__containerTokenInfo}>
                    <input type="text" placeholder="0x" id="address" />
                    <div className={styles.selectData}>
                      <img src="./usdc.png" alt="token" />
                      <p>USDC</p>
                    </div>
                  </div>
                </div>
              </Card>
            </Box>
            {flagTypeAction === "nothing" ? (
              <Button
                color="indigo"
                variant="solid"
                size="4"
                onClick={transfer}
              >
                Transferir
              </Button>
            ) : (
              <Button disabled color="indigo" variant="solid" size="4">
                <Spinner loading />
                Transferir
              </Button>
            )}
          </div>
        </Card>
      </Box>
    </main>
  );
};
