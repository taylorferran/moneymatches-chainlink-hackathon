import Head from "next/head";
import styles from "../styles/Home.module.css";
import Web3Modal from "web3modal";
import { providers, Contract, utils, BigNumber } from "ethers";
import { useEffect, useRef, useState } from "react";
import { MONEYMATCHES_ADDRESS, abi } from "../constants";

export default function Home() {
  const [walletConnected, setWalletConnected] = useState(false);
  const web3ModalRef = useRef();
  const [viewWagerAmount, setWagerAmount] = useState("");
  const [viewGameID, setGameID] = useState("");
  const [viewHeroForGameSelected, setHeroForGameSelected] = useState("");
  const [viewVillainForGameSelected, setVillainForGameSelected] = useState("");
  const [viewWagerForGameSelected, setWagerForGameSelected] = useState("");
  const [viewWinnerForGameSelected, setWinnerForGameSelected] = useState("");
  const [viewPaidOutForGameSelected, setPaidOutForGameSelected] = useState("");

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

        setHeroForGameSelected(tx[0]);
        setVillainForGameSelected(tx[1]);
        setWagerForGameSelected(tx[2]);
        setWinnerForGameSelected(tx[3]);
        setPaidOutForGameSelected(tx[4]);

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

    const canJoinGame = async () => { 

      try {
      if(String(viewVillainForGameSelected) == "0x0000000000000000000000000000000000000000") {
          return 0;
        }
        else {
          return 1;
        }
      } catch(err) {
        console.error(err);
      }

    };

    const canCancelGame = async () => { 

      try {
      if(String(viewHeroForGameSelected) === "TODO put wallet connected address here"
        && viewPaidOutForGameSelected === false
        && viewWagerForGameSelected > 0
        ) {
          return true;
        }
        else {
          return false;
        }
      } catch(err) {
        console.error(err);
      }

    };
    
    const canSettleGame = async () => { 

      try {
      if(String(viewW) === "0x0000000000000000000000000000000000000000") {
          return true;
        }
        else {
          return false;
        }
      } catch(err) {
        console.error(err);
      }

    };

  const connectWallet = async () => {
    try {
      await getProviderOrSigner();
      setWalletConnected(true);
    } catch (err) {
      console.error(err);
    }
  };

  const connectWalletButton = () => {
    if (walletConnected) {
      return (
        (null)
      );
  } else {
    return (
      <button onClick={connectWallet} className={styles.button}>
        Connect your wallet
      </button>
    );
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
            <div>
              <table>
                <tr>
                  <th>Hero</th>
                  <td className={styles.center}>{String(viewHeroForGameSelected)}</td>
                </tr>
                <tr>
                  <th>Villain</th>
                  <td className={styles.center}>{String(viewVillainForGameSelected)}</td>
                </tr>
                <tr>
                  <th>Wager</th>
                  <td className={styles.center}>{String(viewWagerForGameSelected)}</td>
                </tr>
                <tr>
                  <th>Winner</th>
                  <td className={styles.center}>{String(viewWinnerForGameSelected)}</td>
                </tr>
                <tr>
                  <th>Paid Out</th>
                  <td className={styles.center}>{String(viewPaidOutForGameSelected)}</td>
                </tr>
            </table>
          </div>
          );
      }
    };

    const acceptGameButton = () => {

      return (
        <div className={styles.buttonSpace}>
        <button onClick={acceptGame} className={styles.button}>
          Accept game
        </button>
  

        <button onClick={cancelGame} className={styles.button}>
          Cancel game
        </button>

        <button onClick={settleGame} className={styles.button}>
          Settle game
        </button>
        </div>
      );
    };


    const launchGameButton = () => {
      if (walletConnected) {
          return (
          <a href="http://localhost:3001/multiplayer" target="_blank" >Launch Game</a>
          );
      }
    };

    const wagerInput = () => {
      if (walletConnected) {
          return (
            <div>
              <input
                placeholder="Wager"
                onChange={wagerAmount}
                className={styles.input}
              />
              <button onClick={createGame} class = "center">
                Create game
              </button>
            </div>
          );
      }
    };

    const gameIdInput = () => {
      if (walletConnected) {
          return (
            <div>
            <input
            placeholder="GameID"
            onChange={gameID}
            className={styles.input}
            />
            <button onClick={viewGame} class="center">
                View Game Details
              </button>
            </div>
          );
      }
    };

  useEffect(() => {
    if (!walletConnected) {
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
        <link rel="icon" href="/favicon.png" />
      </Head>
      <div className={styles.main}>
          <h1 className={styles.title}>💸  Money Matches 💸</h1>
          <div className={styles.description}>
            It's an onchain pvp matchmaking platform
          </div>
          {connectWalletButton()}
          {wagerInput()}
          <div>
          <p></p>
          </div>
          {gameIdInput()}
          <p></p>
          {viewGameButton()}
          <p></p>
          {acceptGameButton()}
          <p></p>
          {launchGameButton()}
      </div>
      <div>
    </div>
    </div>
  );
}