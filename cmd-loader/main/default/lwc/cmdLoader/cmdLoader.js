/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

import { LightningElement, track } from "lwc";
import retrieveCustomMetadataTypes from "@salesforce/apex/CMDLoaderController.retrieveCustomMetadataTypes";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import PapaParse from "@salesforce/resourceUrl/PapaParse";
import { loadScript } from "lightning/platformResourceLoader";
import upsertRecords from "@salesforce/apex/CMDLoaderController.upsertRecords";
import checkDeployment from "@salesforce/apex/CMDLoaderController.checkDeployment";

const MAX_PREVIEW_ROWS = 200;
const DEPLOYMENT_FAILED_FOR_UNKNOWN_REASON = {
  body: {
    message:
      "Failed to schedule deploy. If your CSV file is very big (more than 500 rows) try to split it in smaller chunks and try again"
  }
};

export default class CmdLoader extends LightningElement {
  @track cmdTypes = [];
  @track cmdRecords = [];

  @track columns = [];

  @track selectedType;

  @track deployResult = {};

  @track csvHasDeveloperName = false;

  @track showPreviewAnyway = false;

  @track showLoadingSpinner = false;

  papaParseLoaded = false;
  deploymentId;
  checkDeployIntervalId;

  get showPreview() {
    return (
      this.cmdRecords.length &&
      (!this.tooManyRowsForPreview || this.showPreviewAnyway)
    );
  }

  get tooManyRowsForPreview() {
    return this.cmdRecords.length > MAX_PREVIEW_ROWS;
  }

  get disableLoad() {
    return (
      !this.cmdRecords.length ||
      !this.selectedType ||
      !this.csvHasDeveloperName ||
      this.deploymentId
    );
  }

  get deployResultMessage() {
    return this.isDeployDone
      ? this.deployResult.result
      : "Deployment in progress";
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

  enableShowPreviewAnyway(event) {
    event.preventDefault();
    this.showPreviewAnyway = true;
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

    this.showLoadingSpinner = true;

    upsertRecords({
      cmdType: this.selectedType,
      records: recordWrappers
    })
      .then(data => {
        if (data) {
          this.deploymentId = data;
          this._startCheckDeployPolling();
        } else {
          // it's not clear why this happen since I'd expect the controller to catch it and throw an exception
          // but it does sometime especially with large CSV file
          this._dispatchError(DEPLOYMENT_FAILED_FOR_UNKNOWN_REASON);
        }
        this.showLoadingSpinner = false;
      })
      .catch(err => {
        this._dispatchError(err);
        this.showLoadingSpinner = false;
      });
  }

  _resetState() {
    this.deployResult = {};
    this.cmdRecords = [];
    this.columns = [];
    this.deploymentId = undefined;
    this.csvHasDeveloperName = false;
    this.showPreviewAnyway = false;
    this.showLoadingSpinner = false;
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
      message: err.body.message,
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(toastEvent);
  }
}
