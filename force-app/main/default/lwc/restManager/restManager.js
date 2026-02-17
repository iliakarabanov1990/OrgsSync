import { LightningElement, track } from 'lwc';
import { ShowToastEvent }          from 'lightning/platformShowToastEvent';
import { NavigationMixin }         from "lightning/navigation";

import sendRequast    from "@salesforce/apex/RestManagerController.sendRequast";
import getInitialData from "@salesforce/apex/RestManagerController.getInitialData";

export default class RestManager extends LightningElement {

	@track _recordsData = [];

	_hideIds          = true;
	_isLoading        = true;
	_modalFormVisible = false;
	_modalFormVisible = false;

	_offset = 0;
	_limit  = 5;

	_objectApiName;
	_modalRecordData = null;
	_searchStr       = '';

	_modalMod;
	_fieldsInfo;

	get ui() {
		return {
			datatable: {
				columns     : this.columns,
				recordsData : this._recordsData
			},
			mainForm: {
				header        : this.objectApiName,
				isLoading     : this._isLoading,
				isLoaded      : !this._isLoading,
				objectOptions : this.objectOptions,
				objectApiName : this.objectApiName,
				searchStr     : this.searchStr
			},
			modalForm: {
				header    : this.objectApiName,
				object    : this.objectApiName,
				fields    : this.formFields,
				viewMode  : this._modalMod === 'view',
				isVisible : this._modalFormVisible
			},
			class: {
				modalForm : `modal-form slds-modal slds-fade-in-open slds-backdrop ${this._modalFormVisible ? '' : 'slds-hide'}`
			},
			show : {
				table : this._recordsData.length > 0
			}
		}
	}

	get disablePrevious() { return this._offset <= 0; }

	get disableNext() { return this._recordsData?.length < this._limit; }

	get objectApiName() {
		return this._objectApiName || '';
	}

	get objectOptions() {
		return this._objectOptions || [];
	}

	get searchStr() {
		return this._searchStr || '';
	}

	get formFields() {

		if (!this._fieldsInfo) { return []; }

		const fileds = this._fieldsInfo[this.objectApiName].formFields.map(field => ({
			name  : field,
			label : field,
			value : null,
			class : ''
		}));

		fileds.push({
			name  : 'Id',
			label : 'Id',
			value : null,
			class : 'slds-hide'
		});

		if (!this._modalRecordData) { return fileds; }

		if (this._modalMod === 'edit' || this._modalMod === 'view') {
			for (const field of fileds) {
				field.value = this._modalRecordData[field.name];
			}
		}

		return fileds;
	}

	get columns() {

		if (!this._fieldsInfo) { return []; }

		const columns = this._fieldsInfo[this.objectApiName].listFields.map(field => ({
			label     : field,
			fieldName : field,
			type      : 'text'
		}));

		columns.push({
			type           : 'button',
			label          : 'View',
			cellAttributes : { alignment: 'left' },
			initialWidth   : 80,
			typeAttributes : {
				label   : 'View',
				name    : 'view',
				variant : 'base'
			}
		});

		columns.push({
			type           : 'action',
			typeAttributes : { rowActions: [
					{ label: 'Delete', name: 'delete' },
					{ label: 'Edit',   name: 'edit'   }
				]
			}
		});

		return columns;
	}

	async connectedCallback() {
	try {
			this.toggleSpinner(true);

			const initialData   = await getInitialData();
			this._fieldsInfo    = initialData.fieldsInfo;
			this._namedCred     = initialData.namedCred;
			const objectsList   = initialData.objectsList;

			if (objectsList.length > 0) {
				this._objectOptions = objectsList.map(item => ({ label: item, value: item }));
				this._objectApiName = objectsList[0];
			}

			await this.getRecords();
		} catch(error) {
			this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))
		} finally {
		this.toggleSpinner(false);
		}
	}

	handleRowAction(event) {
		const action = event.detail.action.name;
		const row    = event.detail.row;

		switch (action) {
			case 'delete':
				this.handleDeleteRecord(row.Id);
				break;
			case 'edit':
				this.handleEditRecord(row);
				break;
			case 'view':
				this.handleViewRecord(row);
				break;
			default:
				console.log(`Unhandled action: ${action}`);
				break;
		}
	}

	handleEditRecord(row) {
		this._modalMod = 'edit';
		this.openModal(row);
	}

	handleViewRecord(row) {
		this._modalMod = 'view';
		this.openModal(row);
	}

	openModal(recordData) {
		this._modalRecordData  = recordData;
		this._modalFormVisible = true;
	}

	async handleDeleteRecord(recordId) {
		try {
			this.toggleSpinner(true);

			const param = {
				method: 'DELETE',
				namedCred: this._namedCred,
				paramsMap: {
						'object' : this.objectApiName,
						'Id'     : recordId
					}
				};

			const answer = await sendRequast(param);

			if (answer.status === '200') {

				this._recordsData.splice(this._recordsData.indexOf(this._recordsData.find(el => el.Id === recordId)), 1);
				this._recordsData = [...this._recordsData];

				this.dispatchEvent(new ShowToastEvent({title: 'Record was deleted', variant: 'success', message: JSON.stringify(answer.body)}));

			} else {
				this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: JSON.parse(answer.body)[0].message}));
			}
		}
		catch(error) {
			this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}));
		} finally {
			this.toggleSpinner(false);
		}
	}

	async handleSubmitCreateForm(event) {
		try {
			event.preventDefault();

			this.toggleSpinner(true);

			const fieldToInsert = {};
			for (const field of this.formFields) {
				const fieldName = typeof field === 'string' ? field : field.name;
				if (fieldName != null && event.detail.fields[fieldName] !== undefined) {
					fieldToInsert[fieldName] = event.detail.fields[fieldName];
				}
			}

			const param = {
				method    : this._modalMod === 'edit' ? 'PATCH' : 'POST',
				body      : JSON.stringify([fieldToInsert]),
				namedCred : this._namedCred,
				paramsMap : {
					object : this.objectApiName
				}
			};

			const answer = await sendRequast(param);

			if(answer.status === '200') {
				this._recordsData = [...this._recordsData, ...answer.body];

				this.dispatchEvent(new ShowToastEvent({title: 'Record was created', variant: 'success', message: JSON.stringify(answer.body)}));

				await this.getRecords();
			} else {
				this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: JSON.parse(answer.body)[0].message}))
			}
		} catch(error) {
			this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}));
		} finally {
			this._modalFormVisible = false;
			this._modalMod         = 'view';

			this.toggleSpinner(false);
		}
	}

	handleNewRecord() {
		this._modalFormVisible = true;
		this._modalMod         = 'create';
	}

	handleCloseForm() {
		this._modalFormVisible = false;
		this._modalRecordData  = null;
	}

	handleSearch(event) {
		this._searchStr = event.currentTarget.value.trim();
	}

	async handleSearchtButton() {
		this._offset = 0;
		await this.getRecords();
	}

	toggleSpinner(isLoading) {
		this._isLoading = isLoading;
	}

	async handlePrevious() {
		this._offset -= this._limit;
		await this.getRecords();
	}

	async handleNext() {
		this._offset += this._limit;
		await this.getRecords();
	}

	async getRecords() {
		try {
			this._recordsData = [];
			let answer;

			this.toggleSpinner(true);

			const param = {
				method     : 'GET',
				namedCred  : this._namedCred,
				paramsMap  : {
					object       : this.objectApiName,
					offset       : this._offset,
					limit        : this._limit,
					groupBy      : 'Name',
					searchString : this.searchStr,
					fields       : [...new Set([...this._fieldsInfo[this.objectApiName].formFields, ...this._fieldsInfo[this.objectApiName].listFields])].join(',')
				}
			};

			answer = await sendRequast(param);
			if (answer.status !== '200') {
				this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: JSON.parse(answer.body)[0].message}));
				answer.body = [];
			}

			this._recordsData = answer.body;

		} catch(error) {
			this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}));
		} finally {
			this.toggleSpinner(false);
		}
	}

	handleSaveForm(event) {
		switch (this._modalMod) {
			case 'edit':
				this.handleSubmitCreateForm(event);
				break;
			case 'create':
				this.handleSubmitCreateForm(event);
				break;
			default:
				console.log(`Unhandled action: ${this._modalMod}`);
				break;
		}

		this.handleCloseForm();
	}



	async handleObjectChange(event) {
		this._objectApiName = event.detail.value;
		this._recordsData   = [];
		this._offset        = 0;
		await this.getRecords();
	}
}