import { Box, Button, Card, Spinner } from "@radix-ui/themes";
import styles from "../styles/Deposits.module.css";
import { useState } from "react";
import { readContract, writeContract, getAccount } from "@wagmi/core";
import { config } from "../wagmi";
import { erc20Abi } from "viem";
import Staking from "../../abis/Staking.json";

export const Deposits = () => {
  const data: {
    [key: string]: {
      label: string;
      icon: JSX.Element;
      backgroundColor: "indigo" | "gray";
      tokenAddress: string;
    };
  } = {
    USDC: {
      label: "USDC",
      icon: <img src="./usdc.png" alt="token" />,
      backgroundColor: "indigo",
      tokenAddress: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    },
    ETH: {
      label: "ETH",
      icon: <img src="./eth.png" alt="token" />,
      backgroundColor: "gray",
      tokenAddress: "0x0000000000000000000000000000000000000000",
    },
  };

  const StakingAddress: `0x${string}` =
    "0x8155bFe2bdcDD09bD565D31067646CA3790Bb77a";
  const USDCAddress: `0x${string}` =
    "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  const mUSDAddress: `0x${string}` =
    "0x1932d99C5115a283D9f0919C9e6FE56b2060063B";

  const [value, setValue] = useState<string>("USDC");

  const [flagTypeAction, setFlagTypeAction] = useState<string>("nothing");

  const [amountMUSD, setAmountMUSD] = useState<number>(0);

  const approveTokenTransfer = async () => {
    const account = getAccount(config);

    const amountToDeposit = (
      document.getElementById("amountToDeposit") as HTMLInputElement
    ).value;
    //transformar a wei (6 decimales)
    const amountToDepositWei = BigInt(Number(amountToDeposit) * 10 ** 6);
    readContract(config, {
      abi: erc20Abi,
      address: USDCAddress,
      functionName: "allowance",
      args: [account.address as `0x${string}`, StakingAddress],
    }).then((allowance: any) => {
      console.log(allowance);
      if (BigInt(allowance) >= BigInt(amountToDepositWei)) {
        setFlagTypeAction("deposit");
      } else {
        setFlagTypeAction("waitForApprove");
        writeContract(config, {
          abi: erc20Abi,
          address: USDCAddress,
          functionName: "approve",
          args: [StakingAddress, amountToDepositWei],
        })
          .then(() => {
            setFlagTypeAction("deposit");
          })
          .catch(() => {
            setFlagTypeAction("nothing");
          });
      }
    });
  };

  const stakingUSDC = async () => {
    const amountToDeposit = (
      document.getElementById("amountToDeposit") as HTMLInputElement
    ).value;
    const amountToDepositWei = BigInt(Number(amountToDeposit) * 10 ** 6);
    setFlagTypeAction("waitDeposit");
    writeContract(config, {
      abi: Staking.abi,
      address: StakingAddress,
      functionName: "stakingUSDC",
      args: [amountToDepositWei],
    })
      .then(() => {
        setFlagTypeAction("deposit");
      })
      .catch(() => {
        setFlagTypeAction("deposit");
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
                  <h3>Token a depositar: </h3>{" "}
                  <div className={styles.cardData__containerTokenInfo}>
                    <input
                      type="number"
                      placeholder="0"
                      id="amountToDeposit"
                      onChange={(e) => setAmountMUSD(Number(e.target.value))}
                    />
                    {/*<Select.Root
                      value={value}
                      onValueChange={setValue}
                      size="3"
                    >
                      <Select.Trigger
                        color={data[value].backgroundColor}
                        variant="soft"
                      >
                        <div className={styles.selectData}>
                          {data[value].icon}
                          <p>{data[value].label}</p>
                        </div>
                      </Select.Trigger>
                      <Select.Content position="popper">
                        <Select.Item value="USDC">USDC</Select.Item>
                        <Select.Item value="ETH">ETH</Select.Item>
                      </Select.Content>
                    </Select.Root>*/}
                    <div className={styles.selectData}>
                      <img src="./usdc.png" alt="token" />
                      <p>USDC</p>
                    </div>
                  </div>
                </div>
              </Card>
            </Box>
            <Box>
              <Card asChild>
                <div className={styles.cardData}>
                  <h3>Cantidad de deposito: </h3>
                  <div className={styles.cardData__containerTokenInfo}>
                    <p>${amountMUSD}</p>
                  </div>
                </div>
              </Card>
            </Box>
            {flagTypeAction === "nothing" ? (
              <Button
                color="indigo"
                variant="solid"
                size="4"
                onClick={approveTokenTransfer}
              >
                Verificar permisos de aprobación
              </Button>
            ) : flagTypeAction === "waitForApprove" ? (
              <Button disabled color="indigo" variant="solid" size="4">
                <Spinner loading />
                Verificar permisos de aprobación
              </Button>
            ) : flagTypeAction === "deposit" ? (
              <Button
                color="green"
                variant="solid"
                size="4"
                onClick={stakingUSDC}
              >
                Depositar
              </Button>
            ) : flagTypeAction === "waitDeposit" ? (
              <Button color="green" variant="solid" size="4" disabled>
                <Spinner loading />
                Depositar
              </Button>
            ) : (
              <Spinner />
            )}
          </div>
        </Card>
      </Box>
    </main>
  );
};
