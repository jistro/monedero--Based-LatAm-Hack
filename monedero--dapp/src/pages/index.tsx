import { ConnectButton } from "@rainbow-me/rainbowkit";
import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import { Tabs } from "@radix-ui/themes";
import { Deposits } from "../components/Deposits";
import { Withdraw } from "../components/Withdraw";

const Home: NextPage = () => {
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
        <ConnectButton />

        <div className={styles.grid}>
          <Tabs.Root defaultValue="tab1" orientation="vertical">
            <Tabs.List aria-label="tabs example">
              <Tabs.Trigger value="tab1">Deposito</Tabs.Trigger>
              <Tabs.Trigger value="tab2">Retiro</Tabs.Trigger>
            </Tabs.List>
            <Tabs.Content value="tab1">
              <Deposits />
            </Tabs.Content>
            <Tabs.Content value="tab2">
              <Withdraw />
            </Tabs.Content>
          </Tabs.Root>
        </div>
      </main>

      <footer className={styles.footer}>
        <a href="https://rainbow.me" rel="noopener noreferrer" target="_blank">
          Made with ❤️ by your frens at 🌈
        </a>
      </footer>
    </div>
  );
};

export default Home;
