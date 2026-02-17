import { LightningElement, wire } from 'lwc';
import getCrossOrgData from '@salesforce/apex/DashboardComponentController.getCrossOrgData';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';

export default class DashboardLwc extends LightningElement {
    reportData;
    error;
    loaded = false;
    chartJsInitialized = false;
    ratingCounts = {};
    typeCounts = {};
    kpiTotal = 0;
    tableRows = [];

   async connectedCallback() {

       this.reportData = await getCrossOrgData();
	   console.log(JSON.stringify(this.reportData));
	   this.prepareChartData();
    }

   renderedCallback() {
       if (this.chartJsInitialized || !this.reportData) return;

        this.chartJsInitialized = true;

        loadScript(this, chartjs)// + '/chart.min.js')
            .then(() => {
                this.drawChart();
            })
            .catch(err => {
                console.error('Chart.js load error', err);
                this.error = 'Chart.js load error: ' + err.message;
            });
    }

    prepareChartData() {
        const factRows = this.reportData?.factMap?.['T!T']?.rows || [];
        this.kpiTotal = this.reportData?.factMap?.['T!T']?.aggregates?.[0]?.value || 0;

        this.tableRows = factRows.map(row => {
            let obj = {};
            row.dataCells.forEach((cell, idx) => {
                obj[`col${idx}`] = cell.label || '';
            });
            return obj;
        });

        // Count Rating and Type dynamically
        this.ratingCounts = {};
        this.typeCounts = {};

		console.log(JSON.stringify(factRows));

        factRows.forEach(row => {
            const cells = row.dataCells;

            // Rating: обычно 5-я ячейка (по твоему JSON)
           /* const ratingCell = cells.find(c => ['Hot','Warm','Cold'].includes(c.label));
            if(ratingCell){
                this.ratingCounts[ratingCell.label] = (this.ratingCounts[ratingCell.label] || 0) + 1;
            }*/

			const rating = cells[5]?.label;
			//alert(rating);
			if (rating && rating !== '-') {
				this.ratingCounts[rating] = (this.ratingCounts[rating] || 0) + 1;
				//alert(rating + ': ' + this.ratingCounts[rating]);
			}

			console.log(JSON.stringify(this.ratingCounts));

            // Type: обычно 4-я ячейка с 'Customer - Direct' и т.д.
            const typeCell = cells.find(c => c.label && c.label.includes('Customer') || c.label === 'Prospect');
            if(typeCell){
                this.typeCounts[typeCell.label] = (this.typeCounts[typeCell.label] || 0) + 1;
            }
        });
    }


     drawChart() {
       const canvas = this.template.querySelector('canvas.chart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: Object.keys(this.ratingCounts),
                datasets: [{
                    label: 'Accounts by Rating',
                    data: Object.values(this.ratingCounts),
					backgroundColor: Object.keys(this.ratingCounts).map(r => {
						if(r === 'Hot') return '#FF6384';
						if(r === 'Warm') return '#36A2EB';
						if(r === 'Cold') return '#FFCE56';
						return '#999'; // fallback
						})
                    //backgroundColor: ['#FF6384','#36A2EB','#FFCE56']
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
