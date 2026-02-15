import { LightningElement, api } from 'lwc';
import { ShowToastEvent }        from 'lightning/platformShowToastEvent';


export default class RecordForm extends LightningElement {

    @api objectApiName;
    @api fields;
    @api viewMode;
    /** Object with field API names as keys and values to show in read-only view (e.g. { Name: 'Acme', Phone: '555' }) */
    //@api recordData = {phone: '555', name: 'Acme'};

    get ui() {
        return {
            objectApiName : this.objectApiName,
            viewMode      : this.viewMode,
            fields        : this.fields,
            //recordData    : this.recordData,
            class : {
                saveButton : this.viewMode ? 'slds-hide' : ''
            }
        };
    }

    handleSubmit(event) {
        try {
            event.preventDefault();
            let fields = event.detail?.fields;

            if (!fields || typeof fields !== 'object') { return; }

            const IdValue =this.fields.find(field => field.name === 'Id')?.value;
            fields = { ...fields, ...{Id: IdValue} }

            this.dispatchEvent(new CustomEvent('save', { detail: {fields}}));

        } catch(error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}));
        }
    }

    handleClose(event) {
        event.preventDefault();
        this.dispatchEvent(new CustomEvent('close'));
    }
}