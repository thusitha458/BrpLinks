import React, {useEffect, useState} from 'react';
import {
  Button,
  Linking,
  SafeAreaView,
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
              if (parts?.length) {
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
        if (parts?.length) {
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
          <PasteControl style={styles.pasteControl} />
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
    <SafeAreaView style={styles.safeArea}>
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
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: Colors.lighter,
  },
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  mainContainer: {
    backgroundColor: Colors.white,
  },
  welcomeContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 48,
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
