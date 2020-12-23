<template>
    <div>
        Адрес: 
            <b-form-input 
                v-model="address" 
                placeholder="Введите адрес..."
            ></b-form-input>
        <br>
        MAC: 
            <b-form-input 
                v-model="mac" 
                placeholder="Введите mac..."
                readonly
            ></b-form-input>
        <br>
        Серийный номер: 
            <b-form-input 
                v-model="serial" 
                placeholder="Введите номер..."
            ></b-form-input>
        <br>
        Район:
            <b-form-select 
                v-model="area" 
                :options="Area"
            ></b-form-select>
        <br><br>
        <b-button 
            size="sm"
            variant="success" 
            @click="PostAPI(onu.port, onu.address, onu.serial_number)"
        >Изменить</b-button>
    </div>
</template>
 
<script>
    import { mapGetters } from 'vuex'
    export default {
        props: ['onu'],
        computed: mapGetters(["Area"]),  
        data(){
            return {
                address: '',
                serial: '',
                note: '',
                mac: '',
                area: '',
            }
        },
        methods: {
            PostAPI: async function (port, address, serial_number) {
            console.log(port, address);
            axios.post(`/api/change-onu-data`, { 
                        address: this.address,
                        serial_number: this.serial,
                        ip: this.$route.params.id,
                        port,
                        mac: this.mac,
                        area: this.area
                    }
                );
            }
        },
        mounted() {
            this.address = this.onu.address
            this.serial = this.onu.serial_number
            this.mac = this.onu.mac
            this.port = this.onu.port
            this.area = this.onu.area
        }
    }
</script>