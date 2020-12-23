<template>
  <b-container>
    <b-col lg="6" class="my-1">
      <b-form-group
        label="Sort"
        label-cols-sm="3"
        label-align-sm="right"
        label-size="sm"
        label-for="sortBySelect"
        class="mb-0">
        <b-input-group size="sm">
          <b-form-select v-model="sortBy" :options="sortOptions" class="w-75">
            <template #first>
              <option value="">-- сортировка --</option>
            </template>
            </b-form-select>
          <b-button variant="info" 
            size="sm" 
            @click="UpdateDataOlt($route.params.id)">Опросить OLT
          </b-button>
        </b-input-group>
      </b-form-group>
    </b-col>
    <b-col lg="6" class="my-1">
      <b-form-group
        label="Filter"
        label-cols-sm="3"
        label-align-sm="right"
        label-size="sm"
        label-for="filterInput"
        class="mb-0">
        <b-input-group size="sm">
          <b-form-input
            v-model="filter"
            type="search"
            placeholder="Поиск"
          ></b-form-input>
        </b-input-group>
      </b-form-group>
  </b-col>
    <b-table
      :items="items"
      :fields="fields"
      :filter="filter"
      :sort-by.sync="sortBy">
      <template v-slot:cell(actions)="row">
        <b-button 
          v-b-modal.modal-scrollable 
          size="sm" 
          variant="primary" 
          @click="info(row.item, $event.target)" 
          class="mr-1">Инфо.
        </b-button>
        <b-button 
          size="sm" 
          variant="warning" 
          @click="edit(row.item, $event.target)" 
          class="mr-1">Ред.
        </b-button>
      </template>
      <template v-slot:cell(port)="data">
        <b>{{Math.round(data.value / 256 % 256 - 10)}}/{{data.value % 64}}</b>
        <br><small>{{data.value}}</small>
      </template>
      <template v-slot:cell(mac)="data">
        {{data.value}}
      </template>
    </b-table>

    <b-modal 
      id="modal-scrollable"
      :title="'Информация по ' + infoModal.title"
      v-model="show"
      cancel-title="Закрыть"
      size="lg"
      scrollable>
      <template v-slot:modal-footer>
        <div class="w-100">
          <b-button variant="primary" @click="show=false">Закрыть</b-button>
        </div>
      </template>
      <ModalInfo :onu="infoModal.content"/> 
    </b-modal>

    <b-modal 
      :id="editModal.id" 
      :title="'Редактировать информация по ' + editModal.title"
      ok-only 
      ok-title="Закрыть"
      size="xl">
      <ModalEdit :onu="editModal.content"/> 
    </b-modal>
  </b-container>
</template>

<script>
import ModalInfo from '../ONU/ModalInfo'
import ModalEdit from '../ONU/ModalEdit'
  
  export default {
  data() {
      return {
        items: '',
        Onu: '',
        filter: '',
        search: '',
        sortBy: '',
        show: false,
        fields: [
          { key: 'port', label: 'Port' },
          { key: 'address', sortable: true, label: 'Адрес' },
          { key: 'mac', label: 'MAC' },
          { key: 'power',  label: 'Уровень сигнала' },
          { key: 'actions', label: 'Actions' }
        ],
        infoModal: {
          id: 'info-modal',
          content: '',
          title: ''
        },
        editModal: {
          id: 'edit-modal',
          content: '',
          title: ''
        },        
      }
    },
    components: {
      ModalInfo, ModalEdit
    },
    computed: {
      sortOptions() {
        // Create an options list from our fields
        return this.fields
          .filter(f => f.sortable)
          .map(f => {
            return { text: f.label, value: f.key }
          })
      }
    },
    mounted() {
      axios.get(`/api/onu/onu-list?ip=${this.$route.params.id}`)
      .then(response => {
        this.items = response.data
      })
        // this.renderChart(this.chartdata, this.options)
        // this.$store.dispatch('SwitchListGet')
    },
    methods: {
      info(item, button) {
        this.infoModal.content = item
        this.infoModal.title = item.address
        this.$root.$emit('bv::show::modal', this.infoModal.id, button)
      },
      edit(item, button) {
        this.editModal.content = item
        this.editModal.title = item.address
        this.$root.$emit('bv::show::modal', this.editModal.id, button)
      },
      UpdateDataOlt(ip) {
        this.boxTwo = ''
        this.$bvModal.msgBoxOk('Запрос на обновление отправлен', {
          title: 'Опросить OLT',
          size: 'sm',
          buttonSize: 'sm',
          okVariant: 'success',
          headerClass: 'p-2 border-bottom-0',
          footerClass: 'p-2 border-top-0',
          centered: true
        })
        .then(value => {
          this.boxTwo = value
        })
        axios.get(`/api/switch/update-data?ip=${ip}`)
        .then(response => {
          this.items = response.data
        })
      }    
    }   
  }
</script>