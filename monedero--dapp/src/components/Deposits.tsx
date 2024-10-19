import {
  Box,
  Button,
  Card,
  DropdownMenu,
  Flex,
  Select,
  TextField,
} from "@radix-ui/themes";
import styles from "../styles/Deposits.module.css";
import { useState } from "react";

export const Deposits = () => {
  const data: {
    [key: string]: {
      label: string;
      icon: JSX.Element;
      backgroundColor: "indigo" | "gray";
    };
  } = {
    USDC: {
      label: "USDC",
      icon: <img src="./usdc.png" alt="token" />,
      backgroundColor: "indigo",
    },
    ETH: {
      label: "ETH",
      icon: <img src="./eth.png" alt="token" />,
      backgroundColor: "gray",
    },
  };
  const [value, setValue] = useState<string>("USDC");
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
                    <input type="number" placeholder="0" />
                    <Select.Root
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
                    </Select.Root>
                  </div>
                </div>
              </Card>
            </Box>
            <Box>
              <Card asChild>
                <div className={styles.cardData}>
                  <h3>Cantidad de mUSD: </h3>
                  <p>0</p>
                </div>
              </Card>
            </Box>
            <Button color="indigo" variant="soft" size="4">
              Edit profile
            </Button>
          </div>
        </Card>
      </Box>
    </main>
  );
};
