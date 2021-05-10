import React, { Component } from 'react';
import './Items.css';

class Items extends Component {
  constructor() {
    super();
    this.state = {
      items: []
    }
  }
  render() {
    return (
      <div>
        <div>
          <div>
            <button type="button" className="btn btn-1 btn-1a" onClick={() => {
              fetch('/api/items')
                .then(response => response.json())
                .then(json => this.setState({ items: json }));
            }}>{this.state.items.length > 0 ? 'Rel' : 'L'}oad orders</button>
          </div>
        </div>
        <div>
          <div>
            <button type="button" className="btn btn-1 btn-1a" onClick={() => {
              fetch('/api/items', { method: 'POST' })
                .then(response => response.json())
                .then(json => this.setState({ response: json }));
            }}>Place an order</button>
          </div>
        </div>
          {
            this.state.items.length > 0
              ? <ItemsTable items={this.state.items.slice(0,5)} />
              : <div></div>
          }
      </div>
    );
  }
}


export default Items;


function ItemsTable(props) {
  return (
    <div>
      <h3>Items Catalogue</h3>
      <table className="itemsTable">
        <tbody>
          <tr>
            <th>Order Id</th>
            <th>Created At</th>
            <th>Updated At</th>
            <th>Status</th>
            <th>Workflow Status</th>
          </tr>
          {
            props.items.map((item, i) => (
              <tr key={i}>
                <td>{item.orderId}</td>
                <td>{item.createdAt}</td>
                <td>{item.updatedAt}</td>
                <td>{item.status}</td>
                <td>{item.workflowStatus}</td>
              </tr>
            ))
          }
        </tbody>
      </table>
    </div>
  );
}