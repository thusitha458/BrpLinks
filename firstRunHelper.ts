import AsyncStorage from '@react-native-async-storage/async-storage';

export const markAsNonFirstRun = async () => {
  try {
    await AsyncStorage.setItem('firstRun', 'false');
  } catch (e) {
    // saving error
  }
};

export const isFirstRun = async (): Promise<boolean> => {
  try {
    const value = await AsyncStorage.getItem('firstRun');
    return value !== 'false';
  } catch (e) {
    // error reading value
    return true; // Assume first run if there's an error
  }
};
