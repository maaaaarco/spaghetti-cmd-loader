/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

 /**
  * Custom datatable component, used to display big CSV files
  */
import { LightningElement, api } from "lwc";

export default class CmdDatatable extends LightningElement {
  @api columns;
  @api records;

  get headers() {
    return this.columns.map(column => {
      return column.fieldName;
    });
  }

  get rows() {
    const headers = this.headers;
    return this.records.map((record, idx) => {
      const cells = [];
      headers.forEach(header => {
        cells.push(record[header]);
      });
      return {
        cells,
        id: idx
      };
    });
  }
}
