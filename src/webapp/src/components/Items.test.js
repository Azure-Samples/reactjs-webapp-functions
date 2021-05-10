import React from 'react';
import ReactDOM from 'react-dom';
import Items from './Items';

it('renders without crashing', () => {
  const div = document.createElement('div');
  ReactDOM.render(<Items />, div);
});
