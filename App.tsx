import React, {useEffect, useState} from 'react';
import type {PropsWithChildren} from 'react';
import {
  Linking,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';

import {Colors} from 'react-native/Libraries/NewAppScreen';

import BrpLinksModule from './BrpLinksModule';
import {isFirstRun, markAsNonFirstRun} from './firstRunHelper';

type SectionProps = PropsWithChildren<{
  title: string;
}>;

function Section({children, title}: SectionProps): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  return (
    <View style={styles.sectionContainer}>
      <Text
        style={[
          styles.sectionTitle,
          {
            color: isDarkMode ? Colors.white : Colors.black,
          },
        ]}>
        {title}
      </Text>
      <Text
        style={[
          styles.sectionDescription,
          {
            color: isDarkMode ? Colors.light : Colors.dark,
          },
        ]}>
        {children}
      </Text>
    </View>
  );
}

function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const [code, setCode] = useState<string>('');

  useEffect(() => {
    isFirstRun().then(firstRun => {
      if (firstRun) {
        setCode('Loading...');
        BrpLinksModule.initialize()
          .then((codeFromDeepLink: string) => {
            if (codeFromDeepLink) {
              setCode(codeFromDeepLink);
              return;
            }
            setCode('None found');
          })
          .catch(() => setCode('None found'));
      } else {
        Linking.getInitialURL()
          .then(initialUrl => {
            if (initialUrl) {
              const parts = initialUrl.split('/');
              if (parts?.length) {
                setCode(parts[parts.length - 1]);
                return;
              }
            }
            setCode('999901');
          })
          .catch(() => {
            setCode('None found');
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
        }
      }
    });

    return () => {
      subscription?.remove();
    };
  }, []);

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          <Section title="BRP Links">
            The code you used to open this app is:{' '}
            <Text style={styles.code}>{code}</Text>
          </Section>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: {
    fontWeight: '700',
  },
  code: {
    color: 'red',
  },
});

export default App;
