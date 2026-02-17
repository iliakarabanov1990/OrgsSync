import { LightningElement } from 'lwc';
import getCrossOrgData      from '@salesforce/apex/DashboardComponentController.getCrossOrgData';
import { loadScript }       from 'lightning/platformResourceLoader';
import chartjs              from '@salesforce/resourceUrl/chartjs';

const REPORT_GROUP      = 'T!T';
const RATING_CELL_INDEX = 5;
const RATING_COLORS     = { Hot: '#FF6384', Warm: '#36A2EB', Cold: '#FFCE56' };
const DEFAULT_COLOR     = '#999';

const TABLE_COLUMNS = [
    { label: 'Owner',          fieldName: 'col0', type: 'text' },
    { label: 'Account Name',   fieldName: 'col1', type: 'text' },
    { label: 'Billing State',  fieldName: 'col2', type: 'text' },
    { label: 'Type',           fieldName: 'col3', type: 'text' },
    { label: 'Rating',         fieldName: 'col4', type: 'text' },
    { label: 'Last Activity',  fieldName: 'col5', type: 'text' }
];

export default class DashboardComponent extends LightningElement {
    reportData;
    error;
    chartJsInitialized = false;
    ratingCounts = {};
    typeCounts = {};
    kpiTotal = 0;
    tableRows = [];

    get tableColumns() {
        return TABLE_COLUMNS;
    }

    async connectedCallback() {
        try {
            this.reportData = await getCrossOrgData();
            this.prepareChartData();
        } catch (err) {
            this.error = err?.body?.message || err?.message || 'Failed to load dashboard data';
        }
    }

    renderedCallback() {
        if (this.chartJsInitialized || !this.reportData || Object.keys(this.ratingCounts).length === 0) {
            return;
        }
        this.chartJsInitialized = true;

        loadScript(this, chartjs)
            .then(() => this.drawChart())
            .catch((err) => {
                this.error = `Chart.js load error: ${err?.message || err}`;
                this.chartJsInitialized = false;
            });
    }

    prepareChartData() {
        const factMap = this.reportData?.factMap?.[REPORT_GROUP] || {};
        const factRows = factMap.rows || [];
        this.kpiTotal = factMap.aggregates?.[0]?.value ?? 0;

        this.tableRows = factRows.map((row, rowIndex) => {
            const obj = { rowId: `row-${rowIndex}` };
            (row.dataCells || []).forEach((cell, idx) => {
                obj[`col${idx}`] = cell?.label ?? '';
            });
            return obj;
        });

        this.ratingCounts = {};
        this.typeCounts = {};

        factRows.forEach((row) => {
            const cells = row.dataCells || [];

            const rating = cells[RATING_CELL_INDEX]?.label;
            if (rating && rating !== '-') {
                this.ratingCounts[rating] = (this.ratingCounts[rating] || 0) + 1;
            }

            const typeCell = cells.find(
                (c) => c?.label && (c.label.includes('Customer') || c.label === 'Prospect')
            );
            if (typeCell?.label) {
                this.typeCounts[typeCell.label] = (this.typeCounts[typeCell.label] || 0) + 1;
            }
        });
    }

    drawChart() {
        const canvas = this.template.querySelector('canvas.chart');
        if (!canvas) return;

        const labels = Object.keys(this.ratingCounts);
        const data = Object.values(this.ratingCounts);
        const backgroundColor = labels.map((r) => RATING_COLORS[r] ?? DEFAULT_COLOR);

        new Chart(canvas.getContext('2d'), {
            type: 'bar',
            data: {
                labels,
                datasets: [{
                    label: 'Accounts by Rating',
                    data,
                    backgroundColor
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    title: { display: true, text: 'Accounts Rating Distribution' }
                }
            }
        });
    }
}
