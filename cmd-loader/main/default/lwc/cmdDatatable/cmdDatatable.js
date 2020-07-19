import { LightningElement, api } from "lwc";
import Header from "@salesforce/schema/PromptVersion.Header";

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
