import {requireNativeComponent, ViewStyle} from 'react-native';
import React from 'react';

const BRPPasteControl = requireNativeComponent('BRPPasteControl');

export default function PasteControl(props: {style?: ViewStyle}) {
  return <BRPPasteControl {...props} />;
}
