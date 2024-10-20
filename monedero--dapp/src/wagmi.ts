import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  //baseSepolia,
  sepolia,
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'RainbowKit App',
  projectId: 'YOUR_PROJECT_ID',
  chains: [
    //baseSepolia,
    sepolia,
  ],
  ssr: true,
});