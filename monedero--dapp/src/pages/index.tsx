import { ConnectButton, WalletButton } from "@rainbow-me/rainbowkit";
import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import { Tabs } from "@radix-ui/themes";
import { Deposits } from "../components/Deposits";
import { Withdraw } from "../components/Withdraw";
import { Withdraw24Hours } from "../components/Withdraw24Hours";
import { getName } from "@coinbase/onchainkit/identity";
import { base } from "viem/chains";
import { getAccount, readContract } from "@wagmi/core";
import { config } from "../wagmi";
import { useEffect, useState } from "react";
import { erc20Abi } from "viem";
import { Transfer } from "../components/Transfer";

const Home: NextPage = () => {
  const StakingAddress: `0x${string}` =
    "0x8155bFe2bdcDD09bD565D31067646CA3790Bb77a";
  const USDCAddress: `0x${string}` =
    "0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8";
  const mUSDAddress: `0x${string}` =
    "0x1932d99C5115a283D9f0919C9e6FE56b2060063B";
  // checa si hay una wallet conectada usando getAccount(config).address
  const [isConnected, setIsConnected] = useState(false);
  const [name, setName] = useState("");
  const [nUSDC_amount, setNUSDC_amount] = useState("0");

  useEffect(() => {
    function checkConnection() {
      const connected = getAccount(config).isConnected;
      setIsConnected(connected);
    }

    checkConnection(); // Verificar la conexión inicial

    // Configurar un intervalo para verificar periódicamente
    const intervalId = setInterval(checkConnection, 1000); // Verifica cada segundo

    // Limpieza del efecto
    return () => clearInterval(intervalId);
  }, []); // Array de dependencias vacío

  useEffect(() => {
    if (isConnected) {
      console.log("hay una wallet conectada");
      getNameAndnUSDC();
    } else {
      console.log("no hay una wallet conectada");
    }
  }, [isConnected]);

  const getNameAndnUSDC = async () => {
    const address = getAccount(config).address;
    const name = await getName({ address, chain: base });
    console.log(name);
    await readContract(config, {
      abi: erc20Abi,
      address: mUSDAddress,
      functionName: "balanceOf",
      args: [address as `0x${string}`],
    })
      .then((rawBalance: any) => {
        console.log(rawBalance);
        setNUSDC_amount((Number(rawBalance) / 1e6).toString()); // Assuming the token has 6 decimal places
        setName(name ? name : "");
      })
      .catch((error) => {
        setNUSDC_amount("0");
        setName(name ? name : "");
        console.log(nUSDC_amount);
      });
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>RainbowKit App</title>
        <meta
          content="Generated by @rainbow-me/create-rainbowkit"
          name="description"
        />
        <link href="/favicon.ico" rel="icon" />
      </Head>

      <main className={styles.main}>
        <div className={styles.dataWallet}>
          <div className={styles.dataWallet_container}>
            <ConnectButton
              showBalance={false}
              accountStatus="address"
              chainStatus="icon"
            />
          </div>

          {isConnected ? (
            <div className={styles.dataWallet_container}>
              <h3>{name}</h3>
              <p>${nUSDC_amount}</p>
            </div>
          ) : (
            "Conéctate a tu wallet"
          )}
        </div>

        <Tabs.Root defaultValue="tab1" orientation="vertical">
          <Tabs.List color="indigo">
            <Tabs.Trigger value="tab1">
              <h3
                style={{
                  color: "white",
                }}
              >
                Deposito
              </h3>
            </Tabs.Trigger>
            <Tabs.Trigger value="tab2">
              <h3
                style={{
                  color: "white",
                }}
              >
                Retiro inmediato
              </h3>
            </Tabs.Trigger>
            <Tabs.Trigger value="tab3">
              <h3
                style={{
                  color: "white",
                }}
              >
                Retiro esperado
              </h3>
            </Tabs.Trigger>
            <Tabs.Trigger value="tab4">
              <h3
                style={{
                  color: "white",
                }}
              >
                Transferencia
              </h3>
            </Tabs.Trigger>
          </Tabs.List>
          <Tabs.Content value="tab1">
            <Deposits />
          </Tabs.Content>
          <Tabs.Content value="tab2">
            <Withdraw />
          </Tabs.Content>
          <Tabs.Content value="tab3">
            <Withdraw24Hours />
          </Tabs.Content>
          <Tabs.Content value="tab4">
            <Transfer />
          </Tabs.Content>
        </Tabs.Root>
      </main>
    </div>
  );
};

export default Home;
