import Head from "next/head";
import styles from "../styles/Home.module.css";
import Web3Modal from "web3modal";
import { providers, Contract, utils, BigNumber } from "ethers";
import { useEffect, useRef, useState } from "react";
import { MONEYMATCHES_ADDRESS, abi } from "../constants";

export default function Home() {
  const [walletConnected, setWalletConnected] = useState(false);
  const web3ModalRef = useRef();
  const [viewWagerAmount, setWagerAmount] = useState("test");
  const [viewGameID, setGameID] = useState("test");

  const wagerAmount = event => {
    setWagerAmount(event.target.value);
  };

  const gameID = event => {
    setGameID(event.target.value);
  };

  const getProviderOrSigner = async (needSigner = false) => {
    // Connect to Metamask
    // Since we store `web3Modal` as a reference, we need to access the `current` value to get access to the underlying object
    const provider = await web3ModalRef.current.connect();
    const web3Provider = new providers.Web3Provider(provider);

    // If user is not connected to the Goerli network, let them know and throw an error
    const { chainId } = await web3Provider.getNetwork();
    if (chainId !== 5) {
      window.alert("Change network to Goerli");
      throw new Error("Change network to Goerli");
    }

    if (needSigner) {
      const signer = web3Provider.getSigner();
      return signer;
    }
    return web3Provider;
  };


  const createGame = async () => {
    try {
      const signer = await getProviderOrSigner(true);
      const moneymatchesContract = new Contract(
        MONEYMATCHES_ADDRESS,
        abi,
        signer
      );
      
      const oneEther = BigNumber.from("1000000000000000000");
      //const value = utils.formatEther(viewWagerAmount);

      
      const value = utils.parseUnits(viewWagerAmount, "ether");
      const tx = await moneymatchesContract.createGame(value, {
        value: value,
      });
      
      await tx.wait();
    } catch (err) {
      console.error(err);
    }
  };

  const acceptGame = async () => {
    try {
      const signer = await getProviderOrSigner(true);

      const moneymatchesContract = new Contract(
        MONEYMATCHES_ADDRESS,
        abi,
        signer
      );
      
      const gameData = await moneymatchesContract.matchList(String(viewGameID));

      //const value = 0.001 * 1;
      const tx = await moneymatchesContract.acceptGame(String(viewGameID), {
        value: gameData[2],
      });

      await tx.wait();
    } catch (err) {
      console.error(err);
    }
  };


     const viewGame = async () => {
      try {
        const provider = await getProviderOrSigner();
        const moneymatchesContract = new Contract(
          MONEYMATCHES_ADDRESS,
          abi,
          provider
        );
        const tx = await moneymatchesContract.matchList(String(viewGameID));

        if(tx) {
          alert(tx);
        }
        alert
      } catch (err) {
        console.error(err);
      }
    };

    const settleGame = async () => {
      try {
        const signer = await getProviderOrSigner(true);
  
        const moneymatchesContract = new Contract(
          MONEYMATCHES_ADDRESS,
          abi,
          signer
        );
  
        const tx = await moneymatchesContract.requestWinnerFromGameID(String(viewGameID));
        await tx.wait();
      } catch (err) {
        console.error(err);
      }
    };
  
    const cancelGame = async () => {
      try {
        const signer = await getProviderOrSigner(true);
  
        const moneymatchesContract = new Contract(
          MONEYMATCHES_ADDRESS,
          abi,
          signer
        );
  
        const tx = await moneymatchesContract.cancelGameBeforeItHasBeenAccepted(String(viewGameID));
        await tx.wait();
      } catch (err) {
        console.error(err);
      }
    };

  /*
    connectWallet: Connects the MetaMask wallet
  */
  const connectWallet = async () => {
    try {
      // Get the provider from web3Modal, which in our case is MetaMask
      // When used for the first time, it prompts the user to connect their wallet
      await getProviderOrSigner();
      setWalletConnected(true);

    } catch (err) {
      console.error(err);
    }
  };

  const createGameButton = () => {
    if (walletConnected) {
        return (
          <button onClick={createGame} className={styles.button}>
            Create game
          </button>
        );
    } else {
      return (
        (null)
      );
    }
  };


    const viewGameButton = () => {
      if (walletConnected) {
          return (
            <button onClick={viewGame} className={styles.button}>
              View Game Details
            </button>
          );
      }
    };

    const acceptGameButton = () => {
      if (walletConnected) {
          return (
            <button onClick={acceptGame} className={styles.button}>
              Accept game
            </button>
          );
      } else {
        return (
          <button onClick={connectWallet} className={styles.button}>
            Connect your wallet
          </button>
        );
      }
    };

    const cancelGameButton = () => {
      if (walletConnected) {
          return (
            <button onClick={cancelGame} className={styles.button}>
              Cancel game
            </button>
          );
      } else {
        return (
          <button onClick={connectWallet} className={styles.button}>
            Connect your wallet
          </button>
        );
      }
    };
  
    const settleGameButton = () => {
      if (walletConnected) {
          return (
            <button onClick={settleGame} className={styles.button}>
              Settle game
            </button>
          );
      } else {
        return (
          <button onClick={connectWallet} className={styles.button}>
            Connect your wallet
          </button>
        );
      }
    };

  useEffect(() => {
    // if wallet is not connected, create a new instance of Web3Modal and connect the MetaMask wallet
    if (!walletConnected) {
      // Assign the Web3Modal class to the reference object by setting it's `current` value
      // The `current` value is persisted throughout as long as this page is open
      web3ModalRef.current = new Web3Modal({
        network: "goerli",
        providerOptions: {},
        disableInjectedProvider: false,
      });
      connectWallet();
    }
  }, [walletConnected]);

  return (
    <div>
      <Head>
        <title>Money Matches</title>
        <meta name="description" content="moneymatches dapp" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className={styles.main}>
        <div>
          <h1 className={styles.title}>This is a moneymatches dapp</h1>
          <div className={styles.description}>
            It's an onchain pvp framework.
          </div>
          <input
            placeholder="Wager"
            onChange={wagerAmount}
            className={styles.input}
            />
          {createGameButton()}
          <input
            placeholder="Game ID"
            onChange={gameID}
            className={styles.input}
            />
        </div>
          {viewGameButton()}
          {acceptGameButton()}
          {cancelGameButton()}
          {settleGameButton()}
      </div>
    </div>
  );
}