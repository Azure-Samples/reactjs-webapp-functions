import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
import Items from './components/Items';

class App extends Component {
  constructor() {
    super();
    this.state = { message: '' };
  }

  componentDidMount() {
    fetch('/api/message')
      .then(response => response.json())
      .then(json => this.setState({ message: json }))
      .catch(error => this.setState({ message: 'Welcome'}));
  }

  render() {
    return (
      <div className="App">
        <div className="App-header">
          <img src={logo} className="App-logo" alt="logo" />
          <h2>{this.state.message}</h2>
        </div>
        <br/>
        <Items />
      </div>
    );
  }
}

export default App;
