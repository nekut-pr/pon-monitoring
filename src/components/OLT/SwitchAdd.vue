<template>
   <div>
        <form @submit.prevent="PostAPI()">
            ip: <input v-model="ip" type="ip" required><br>
            name: <input v-model="name" type="name" required>
            <p>
                <label>Выбери модель</label>
                <select v-model="selected" >
                    <option v-for="option in select" v-bind:key="option.vendor">{{option.vendor}} {{option.model}}</option>
                </select>
            </p>
            <button type="submit">Отправить форму</button>
        </form>
    </div>
</template>        

<script>
export default {
    data () { return { 
            name: null, 
            ip: null,
            selected: null,
            select: [
                { vendor: 'Cdata', model: 'FD1612S' },
                { vendor: 'BDCOM', model: 'P3310C-AC' },
            ] 
        }
    },
    methods: {
        PostAPI: function (){
                let res = axios.post(`/api/switch-add`, 
                    { 
                        name:   this.name, 
                        ip:     this.ip, 
                        vendor: this.selected.split(" ")[0], 
                        model:  this.selected.split(" ")[1]
                    }
                );
            }
        }
    }
</script>