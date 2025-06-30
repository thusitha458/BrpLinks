import {requireNativeComponent, ViewStyle} from 'react-native';
import React from 'react';

type TextPastedEvent = {
  nativeEvent: {
    value: string;
  };
};

const BRPPasteControl = requireNativeComponent('BRPPasteControl');

export default function PasteControl(props: {
  style?: ViewStyle;
  onTextPasted: (event: TextPastedEvent) => unknown;
}) {
  return <BRPPasteControl {...props} />;
}
