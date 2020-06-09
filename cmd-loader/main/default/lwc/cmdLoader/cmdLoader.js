import { LightningElement, track } from "lwc";
import retrieveCustomMetadataTypes from "@salesforce/apex/CMDLoaderController.retrieveCustomMetadataTypes";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import PapaParse from "@salesforce/resourceUrl/PapaParse";
import { loadScript } from "lightning/platformResourceLoader";
import upsertRecords from "@salesforce/apex/CMDLoaderController.upsertRecords";
import checkDeployment from "@salesforce/apex/CMDLoaderController.checkDeployment";

export default class CmdLoader extends LightningElement {
  @track cmdTypes = [];
  @track cmdRecords = [];

  @track headers;

  @track selectedType;

  @track deployResult = {};

  papaParseLoaded = false;
  deploymentId;
  checkDeployIntervalId;

  get showPreview() {
    return this.cmdRecords.length;
  }

  get disableLoad() {
    return !this.cmdRecords.length || !this.selectedType;
  }

  get deployResultMessage() {
    return this.deployResult.result;
  }

  get resultThemeClass() {
    return this.deployResult.success
      ? "slds-theme_success"
      : "slds-theme_error";
  }

  get isDeployDone() {
    return this.deployResult.done;
  }

  renderedCallback() {
    if (this.papaParseLoaded) {
      return;
    }

    loadScript(this, PapaParse + "/papaparse.min.js")
      .then(() => {
        this.papaParseLoaded = true;
      })
      .catch(err => {
        this._dispatchError(err);
      });
  }

  connectedCallback() {
    retrieveCustomMetadataTypes()
      .then(data => {
        this.cmdTypes = data;
      })
      .catch(err => {
        this._dispatchError(err);
      });
  }

  handleCmdTypeSelection(event) {
    this.selectedType = event.target.value;
  }

  handleFileChange(event) {
    this._resetState();
    if (event.target.files && event.target.files.length) {
      this._parseCsvAndDisplayPreview(event.target.files[0]);
    }
  }

  _parseCsvAndDisplayPreview(file) {
    const fileReader = new FileReader();

    fileReader.addEventListener("load", event => {
      const parseResult = Papa.parse(event.target.result, {
        skipEmptyLines: true
      });

      this.headers = parseResult.data.splice(0, 1)[0];
      this.cmdRecords = parseResult.data;
    });

    fileReader.readAsText(file);
  }

  loadRecords() {
    const recordWrappers = [];

    for (let i = 0; i < this.cmdRecords.length; i++) {
      let record = {
        fields: []
      };

      let columns = this.cmdRecords[i];

      for (let j = 0; j < columns.length; j++) {
        record.fields.push({
          fieldName: this.headers[j],
          fieldValue: columns[j]
        });
      }

      recordWrappers.push(record);
    }

    upsertRecords({
      cmdType: this.selectedType,
      records: recordWrappers
    })
      .then(data => {
        this.deploymentId = data;
        this._startCheckDeployPolling();
      })
      .catch(err => {
        console.log(err);
      });
  }

  _resetState() {
    this.deployResult = {};
    this.cmdRecords = [];
    this.deploymentId = undefined;
  }

  _startCheckDeployPolling() {
    if (!this.checkDeployIntervalId) {
      this.checkDeployIntervalId = setInterval(() => {
        checkDeployment({
          deployId: this.deploymentId
        })
          .then(response => {
            this.deployResult = response;
            clearInterval(this.checkDeployIntervalId);
            this.checkDeployIntervalId = null;
          })
          .catch(err => {
            // this._dispatchError(err);
            console.error(err);
            clearInterval(this.checkDeployIntervalId);
            this.checkDeployIntervalId = null;
          });
      }, 2000);
    }
  }

  _dispatchError(err) {
    const toastEvent = new ShowToastEvent({
      title: "error",
      message: err.body.message,
      variant: "error"
    });
    this.dispatchEvent(toastEvent);
  }
}
