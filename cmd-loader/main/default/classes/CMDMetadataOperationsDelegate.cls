/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

/**
 * This Delegate allows for testing with mocks
 */
public inherited sharing class CMDMetadataOperationsDelegate {
    public Id enqueueDeployment(Metadata.DeployContainer container, Metadata.DeployCallback callback) {
      return Metadata.Operations.enqueueDeployment(container, callback);
    }
}
