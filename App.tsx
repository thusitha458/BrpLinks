import React, {useEffect, useState} from 'react';
import {
  Button,
  Linking,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import {Colors} from 'react-native/Libraries/NewAppScreen';

import BrpLinksModule from './BrpLinksModule';
import {isFirstRun, markAsNonFirstRun} from './firstRunHelper';
import PasteControl from './BRPPasteControl';
import {getCurrentProviderCode, setProviderCode} from './providerCodeHelper';

enum Screen {
  Loading,
  Welcome,
  CodeInput,
  GymDetails,
}

function App(): React.JSX.Element {
  const [screen, setScreen] = useState<Screen>(Screen.Loading);

  const [code, setCode] = useState<string>('');
  const [inputCode, setInputCode] = useState<string>('');

  useEffect(() => {
    const checkForStoredProviderCode = () => {
      getCurrentProviderCode().then(current => {
        if (current) {
          setScreen(Screen.GymDetails);
          setCode(current);
          return;
        }
        setScreen(Screen.CodeInput);
      });
    };

    isFirstRun().then(firstRun => {
      if (firstRun) {
        BrpLinksModule.initialize()
          .then((codeFromDeepLink: string) => {
            if (codeFromDeepLink === '__pasteboard_contains_a_number__') {
              // ios only
              setScreen(Screen.Welcome);
              return;
            }

            if (codeFromDeepLink) {
              setCode(codeFromDeepLink);
              setProviderCode(codeFromDeepLink);
              setScreen(Screen.GymDetails);
              return;
            }
            getCurrentProviderCode().then(current => {
              if (current) {
                setCode(current);
                setScreen(Screen.GymDetails);
                return;
              }
              setScreen(Screen.CodeInput);
              checkForStoredProviderCode();
            });
          })
          .catch(() => checkForStoredProviderCode());
      } else {
        Linking.getInitialURL()
          .then(initialUrl => {
            if (initialUrl) {
              const parts = initialUrl.split('/');
              if (parts?.length && parts[parts.length - 1]?.length === 6) {
                setCode(parts[parts.length - 1]);
                setProviderCode(parts[parts.length - 1]);
                setScreen(Screen.GymDetails);
                return;
              }
            }
            checkForStoredProviderCode();
          })
          .catch(() => {
            checkForStoredProviderCode();
          });
      }
      markAsNonFirstRun();
    });
  }, []);

  useEffect(() => {
    const subscription = Linking.addEventListener('url', event => {
      const url = event?.url;
      if (url) {
        const parts = url.split('/');
        if (parts?.length && parts[parts.length - 1]?.length === 6) {
          setCode(parts[parts.length - 1]);
          setProviderCode(parts[parts.length - 1]);
          setScreen(Screen.GymDetails);
        }
      }
    });

    return () => {
      subscription?.remove();
    };
  }, []);

  const renderWelcomeContent = () => {
    if (screen !== Screen.Welcome) {
      return null;
    }

    return (
      <View style={styles.welcomeContainer}>
        <Text style={styles.sectionTitle}>Welcome to GoActive!</Text>
        <Text style={styles.welcomeText}>
          We'll personalize your experience by loading your gym details. Tap the
          Paste button below to continue.
        </Text>
        <View style={styles.pasteControlContainer}>
          <PasteControl
            style={styles.pasteControl}
            onTextPasted={e => {
              if (e?.nativeEvent?.value) {
                const pastedCode = e.nativeEvent.value.trim();
                if (
                  pastedCode.length === 7 &&
                  !isNaN(Number(pastedCode)) &&
                  Number(pastedCode) > 1000000 &&
                  Number(pastedCode) <= 1999999
                ) {
                  const updatedCode = pastedCode.slice(1);

                  setCode(updatedCode);
                  setProviderCode(updatedCode);
                  setScreen(Screen.GymDetails);
                  return;
                }

                const checkForStoredProviderCode = () => {
                  getCurrentProviderCode().then(current => {
                    if (current) {
                      setScreen(Screen.GymDetails);
                      setCode(current);
                      return;
                    }
                    setScreen(Screen.CodeInput);
                  });
                };

                BrpLinksModule.iosContinueWithoutPasting()
                  .then((codeFromDeepLink: string) => {
                    if (codeFromDeepLink) {
                      setCode(codeFromDeepLink);
                      setProviderCode(codeFromDeepLink);
                      setScreen(Screen.GymDetails);
                      return;
                    }
                    getCurrentProviderCode().then(current => {
                      if (current) {
                        setCode(current);
                        setScreen(Screen.GymDetails);
                        return;
                      }
                      setScreen(Screen.CodeInput);
                      checkForStoredProviderCode();
                    });
                  })
                  .catch(() => checkForStoredProviderCode());
              }
            }}
          />
        </View>
      </View>
    );
  };

  const renderCodeInput = () => {
    if (screen !== Screen.CodeInput) {
      return null;
    }

    return (
      <View>
        <Text style={[styles.sectionTitle, styles.codeInputScreenTitle]}>
          Installation selection
        </Text>

        <View style={styles.codeInputContainer}>
          <TextInput
            style={styles.textInput}
            maxLength={6}
            keyboardType="number-pad"
            placeholder="Enter provider code"
            value={inputCode}
            onChangeText={setInputCode}
          />
          <Button
            title="Done"
            disabled={!inputCode.trim() || inputCode.length !== 6}
            onPress={() => {
              if (inputCode.trim() && inputCode.length === 6) {
                setCode(inputCode);
                setProviderCode(inputCode);
                setInputCode('');
                setScreen(Screen.GymDetails);
              }
            }}
          />
        </View>
      </View>
    );
  };

  const renderGymDetails = () => {
    if (screen !== Screen.GymDetails) {
      return null;
    }

    return (
      <View style={styles.gymDetailsContainer}>
        <Text style={styles.sectionTitle}>Your Gym Details</Text>
        <Text style={styles.gymDetailsText}>
          You are now connected to: {code}
        </Text>
        <View style={styles.exitButtonContainer}>
          <Button
            title="Exit"
            onPress={() => {
              setCode('');
              setProviderCode('');
              setScreen(Screen.CodeInput);
            }}
          />
        </View>
      </View>
    );
  };

  return (
    <View style={styles.root}>
      <StatusBar barStyle={'dark-content'} backgroundColor={Colors.lighter} />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={styles.scrollView}>
        <View style={styles.mainContainer}>
          {renderGymDetails()}
          {renderCodeInput()}
          {renderWelcomeContent()}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    paddingTop: 64,
    backgroundColor: Colors.lighter,
  },
  scrollView: {
    flex: 1,
    backgroundColor: Colors.lighter,
  },
  mainContainer: {
    flex: 1,
    backgroundColor: Colors.lighter,
  },
  welcomeContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 48,
    backgroundColor: Colors.lighter,
  },
  welcomeText: {
    color: Colors.dark,
    marginTop: 8,
    textAlign: 'center',
    paddingHorizontal: 24,
  },
  pasteControlContainer: {
    height: 48,
    width: 100,
    marginTop: 10,
  },
  pasteControl: {
    flex: 1,
  },
  codeInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 12,
    paddingHorizontal: 24,
  },
  textInput: {
    flex: 1,
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    paddingHorizontal: 10,
    marginRight: 10,
  },
  gymDetailsContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 48,
  },
  gymDetailsText: {
    color: Colors.dark,
    marginTop: 8,
    textAlign: 'center',
    paddingHorizontal: 24,
  },
  exitButtonContainer: {
    height: 48,
    width: 100,
    marginTop: 10,
  },
  codeInputScreenTitle: {
    paddingTop: 48,
    paddingBottom: 12,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  highlight: {
    fontWeight: '700',
  },
  code: {
    color: 'red',
  },
});

export default App;
