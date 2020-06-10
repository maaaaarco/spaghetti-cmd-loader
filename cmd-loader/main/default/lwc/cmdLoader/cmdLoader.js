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

  @track columns = [];

  @track selectedType;

  @track deployResult = {};

  @track csvHasDeveloperName = false;

  papaParseLoaded = false;
  deploymentId;
  checkDeployIntervalId;

  get showPreview() {
    return this.cmdRecords.length;
  }

  get disableLoad() {
    return (
      !this.cmdRecords.length || !this.selectedType || !this.csvHasDeveloperName || this.deploymentId
    );
  }

  get deployResultMessage() {
    return this.isDeployDone ? this.deployResult.result : "Deployment in progress";
  }

  get resultThemeClass() {
    return this.deployResult.done
      ? this.deployResult.success
        ? "slds-theme_success"
        : "slds-theme_error"
      : "slds-theme_info";
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
        header: true,
        skipEmptyLines: true
      });

      // creates headers for data-table
      if (parseResult.data.length) {
        const headers = Object.keys(parseResult.data[0]);

        headers.forEach(header => {
          this.columns.push({
            label: header,
            fieldName: header,
            type: "text"
          });

          this.csvHasDeveloperName |= /^DeveloperName$/i.test(header);
        });
      }

      this.cmdRecords = parseResult.data;
    });

    fileReader.readAsText(file);
  }

  loadRecords() {
    const recordWrappers = [];

    this.cmdRecords.forEach(cmdRecord => {
      const recordWrapper = {
        fields: []
      };

      Object.keys(cmdRecord).forEach(field => {
        recordWrapper.fields.push({
          fieldName: field,
          fieldValue: cmdRecord[field]
        });
      });

      recordWrappers.push(recordWrapper);
    });

    upsertRecords({
      cmdType: this.selectedType,
      records: recordWrappers
    })
      .then(data => {
        this.deploymentId = data;
        this._startCheckDeployPolling();
      })
      .catch(err => {
        this._dispatchError(err);
      });
  }

  _resetState() {
    this.deployResult = {};
    this.cmdRecords = [];
    this.columns = [];
    this.deploymentId = undefined;
    this.csvHasDeveloperName = false;
  }

  _startCheckDeployPolling() {
    if (!this.checkDeployIntervalId) {
      this.checkDeployIntervalId = setInterval(() => {
        checkDeployment({
          deployId: this.deploymentId
        })
          .then(response => {
            this.deployResult = response;
            if (response.done) {
              clearInterval(this.checkDeployIntervalId);
              this.checkDeployIntervalId = null;
            }
          })
          .catch(err => {
            this._dispatchError(err);
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
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(toastEvent);
  }
}
