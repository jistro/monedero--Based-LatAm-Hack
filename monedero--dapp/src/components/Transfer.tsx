import { Box, Button, Card, Spinner } from "@radix-ui/themes";
import styles from "../styles/Deposits.module.css";
import { useState } from "react";
import { readContract, writeContract, getAccount } from "@wagmi/core";
import { config } from "../wagmi";
import { erc20Abi } from "viem";
import mUSDC from "../../abis/mUSDC.json";

export const Transfer = () => {
  const StakingAddress: `0x${string}` =
    "0x8155bFe2bdcDD09bD565D31067646CA3790Bb77a";
  const USDCAddress: `0x${string}` =
    "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  const mUSDAddress: `0x${string}` =
    "0x1932d99C5115a283D9f0919C9e6FE56b2060063B";

  const [flagTypeAction, setFlagTypeAction] = useState<string>("nothing");

  const [amountUSD, setAmountUSD] = useState<number>(0);

  const transferToken = async () => {
    console.log("transferToken");
    const amountToDeposit = (
      document.getElementById("amountToTransfer") as HTMLInputElement
    ).value;
    const amountToDepositWei = BigInt(Number(amountToDeposit) * 10 ** 6);

    const accountTo = document.getElementById("address") as HTMLInputElement;
    console.log(accountTo.value);
    console.log(amountToDepositWei);
    setFlagTypeAction("wait");
    writeContract(config, {
      abi: mUSDC.abi,
      address: mUSDAddress,
      functionName: "transfer",
      args: [accountTo.value as `0x${string}`, amountToDepositWei],
    })
      .then(() => {
        setFlagTypeAction("nothing");
      })
      .catch(() => {
        setFlagTypeAction("nothing");
        console.log("error");
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
                      id="amountToTransfer"
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
                    <input type="text" placeholder="0x" id="address" 
                      style={{ fontSize: "2rem"}}
                    />
                    <div className={styles.selectData}>
                      
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
                onClick={transferToken}
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
