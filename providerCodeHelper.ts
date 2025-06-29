import AsyncStorage from '@react-native-async-storage/async-storage';

export const setProviderCode = async (providerCode: string) => {
  try {
    await AsyncStorage.setItem('providerCode', providerCode);
  } catch (e) {
    // saving error
  }
};

export const getCurrentProviderCode = async (): Promise<string | null> => {
  try {
    return (await AsyncStorage.getItem('providerCode')) || null;
  } catch (e) {
    // error reading value
    return null;
  }
};
