<template>
    <div>
      <div class="menu">
        <div class="frame" style="width: 35%; height: 300px;">
            Адрес: {{onu.address}}<br>
            Район: {{onu.area}}<br>
            Серийный номер: {{onu.serial_number}}<br>
            MAC адресс: {{onu.mac}}<br>
            <hr>
            Уровень сигнала: {{onu.power}} db<br>
            Напряжение: {{onu.voltage}} V<br>
            Температура: {{onu.temperature}} °C<br>
            <small>Последняя дата опроса: {{onu["max(date)"]}}</small><br>
            <b-button 
              v-b-modal.modal-multi-1 
              @click="OnuUpdateData(onu.port)">Обновить
            </b-button>
            <hr>
            <b-modal id="modal-multi-1" size="sm" ok-only >
              <p class="my-2">Запрос на отправление отправлен</p>
            </b-modal>
        </div>
        <div class="frame" style="width: 65%; height: 400px;"></div>
      </div>

      <div class="accordion" role="tablist">
        <b-card no-body class="mb-1">
          <b-card-header header-tag="header" class="p-1" role="tab">
            <b-button 
              block 
              v-b-toggle.accordion-2 
              variant="info" 
              @click="History(onu.port)">История сигланов
            </b-button>
          </b-card-header>
          <b-collapse id="accordion-2" accordion="my-accordion" role="tabpanel">
            <b-card-body>
              <b-table
              :items="history.reverse()"
              :fields="fields"
              >
              </b-table>
            </b-card-body>
          </b-collapse>
        </b-card> 
      </div>
    </div>
          <!-- <line-chart
            v-if="loaded"
            :chartdata="GetPower"
            :options="options"
            height="200px"/> -->    
</template>
 
<script>
  import LineChart from './Chart'
    export default {
      props: ['onu'],
      components: { LineChart },
      data () {
        return {
          loaded: false,
          history: [],
          fields: [
            { key: 'date', label: 'Дата' },
            { key: 'power', label: 'Сигнал' },
            { key: 'voltage', label: 'Напряжение' },
            { key: 'temperature', label: 'Температура' },
          ],
          // GetPower: {
          //   labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
          //   datasets: [{
          //     label: 'Уровень сигнала',
          //     borderColor: 'rgb(51,102,0)',
          //     data: [0, 1]
          //   }]
          // },
          options: {}
        }
      },
      computed: {
        GraphPower() {
          return this.$store.getters.GraphPower
        }
      },
      methods: {
        History(port){
          axios.get(`/api/onu/history?ip=${this.$route.params.id}&port=${port}`)
          .then(response => {
            this.history = response.data
          })
        },
        OnuUpdateData(port) {
          axios.get(`/api/onu/update-data?ip=${this.$route.params.id}&port=${port}`)
          .then(response => {
            this.history = response.data
          })
          // axios.get(`/api/onu/update-data?ip=${ip}&port=${port}`)
          //   .then(response => { data = JSON.stringify(response.data)
          // })  
        }
      } 
    }
</script>

<style scoped>
  html, body{
    padding: 0px;
    margin: 0px;
  }
     
  .menu {
    display:flex;
    max-width: 100%;
    height: auto
  }

  .frame{
    display:inline-block;
    width: 50%
  }
    
  img{
    width: 100%
  }
</style>