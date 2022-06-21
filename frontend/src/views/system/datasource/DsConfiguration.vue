<template xmlns:v-slot="http://www.w3.org/1999/XSL/Transform">
  <div>
    <el-row>
      <el-col>
        <el-form
          ref="DsConfig"
          :model="form"
          :rules="rule"
          size="small"
          :disabled="disabled"
          label-width="180px"
          label-position="right"
        >
          <el-form-item v-if="form.type == 'api'" :label="$t('datasource.data_table')">
            <el-col>
              <el-button size="mini" icon="el-icon-plus" type="text" @click="addApiItem(undefined)" />
              <el-table :data="form.apiConfiguration" class="my_table" max-height="300" height="300">
                <el-table-column
                  prop="name"
                  :label="$t('datasource.data_table_name')"
                  width="150"
                  show-overflow-tooltip
                />
                <el-table-column
                  prop="method"
                  :label="$t('datasource.method')"
                  width="150"
                  show-overflow-tooltip
                />
                <el-table-column
                  prop="url"
                  :label="$t('datasource.url')"
                  width="150"
                  show-overflow-tooltip
                />
                <el-table-column prop="status" :label="$t('commons.status')" width="150">
                  <template slot-scope="scope">
                    <span v-if="scope.row.status === 'Success'" style="color: green">
                      {{ $t('datasource.valid') }}
                    </span>
                    <span v-if="scope.row.status === 'Error'" style="color: #ff0000">
                      {{ $t('datasource.invalid') }}
                    </span>
                  </template>
                </el-table-column>

                <el-table-column :label="$t('dataset.operate')">
                  <template slot-scope="scope" style="float: right">
                    <el-button size="mini" type="primary" icon="el-icon-edit" circle @click="addApiItem(scope.row)" />
                    <el-button size="mini" type="danger" icon="el-icon-delete" circle @click="deleteItem(scope.row)" />
                  </template>
                </el-table-column>
              </el-table>
            </el-col>
          </el-form-item>

          <el-dialog
            :title="api_table_title"
            :visible="edit_api_item"
            :before-close="closeEditItem"
            width="60%"
            class="dialog-css"
            append-to-body
          >
            <el-steps :active="active" align-center>
              <el-step title="步骤 1" />
              <el-step title="步骤 2" />
            </el-steps>

            <el-row v-show="active === 1">
              <el-form ref="apiItem" size="small" :model="apiItem" label-width="100px" :rules="rule">
                <p class="tip">{{ $t('datasource.base_info') }} </p>

                <el-form-item :label="$t('commons.name')" prop="name">
                  <el-input v-model="apiItem.name" autocomplete="off" />
                </el-form-item>

                <el-form-item :label="$t('datasource.request')" prop="url">
                  <el-input
                    v-model="apiItem.url"
                    :placeholder="$t('datasource.path_all_info')"
                    class="ms-http-input"
                    size="small"
                  >
                    <el-select slot="prepend" v-model="apiItem.method" style="width: 100px" size="small">
                      <el-option v-for="item in reqOptions" :key="item.id" :label="item.label" :value="item.id" />
                    </el-select>
                  </el-input>
                </el-form-item>

                <div v-loading="loading">
                  <p class="tip">{{ $t('datasource.req_param') }} </p>
                  <!-- HTTP 请求参数 -->
                  <el-form-item>
                    <api-http-request-form
                      :headers="apiItem.request.headers"
                      :request="apiItem.request"
                      :response="responseData"
                    />
                  </el-form-item>
                </div>

                <el-form-item :label="$t('datasource.data_path')">
                  <el-input v-model="apiItem.dataPath" class="ms-http-input" size="small" :disabled="isDisabled">
                    <el-select slot="prepend" v-model="apiItem.dataMethod" style="width: 150px" size="small" @change="checkDataMethod">
                      <el-option v-for="item in dataMethodOptions" :key="item.id" :label="item.label" :value="item.id" />
                    </el-select>
                  </el-input>
                </el-form-item>

              </el-form>
            </el-row>
            <el-row v-show="active === 2">
              <el-tabs v-model="api_step2_active_name">
                <el-tab-pane :label="$t('dataset.data_preview')" name="first">
                  <div class="tab-pane-main">
                    <div v-if="isDisabled" class="tab-pane-left">
                      <div class="wrap">
                        <el-tree
                          ref="tree"
                          :data="treeData"
                          show-checkbox
                          :check-strictly="true"
                          node-key="id"
                          :props="defaultProps"
                          @check-change="treeCheckedChange"
                        />
                      </div>
                    </div>
                    <div class="tab-pane-right">
                      <ux-grid
                        ref="plxTable"
                        size="mini"
                        style="width: 100%;"
                        :height="height"
                        :checkbox-config="{highlight: true}"
                        :width-resize="true"
                      >
                        <ux-table-column
                          v-for="field in apiItem.fields"
                          :key="field.originName"
                          min-width="200px"
                          :field="field.originName"
                          :resizable="true"
                        >
                          <template slot="header">
                            <svg-icon v-if="field.deExtractType === 0" icon-class="field_text" class="field-icon-text" />
                            <svg-icon v-if="field.deExtractType === 1" icon-class="field_time" class="field-icon-time" />
                            <svg-icon
                              v-if="field.deExtractType === 2 || field.deExtractType === 3"
                              icon-class="field_value"
                              class="field-icon-value"
                            />
                            <svg-icon
                              v-if="field.deExtractType === 5"
                              icon-class="field_location"
                              class="field-icon-location"
                            />
                            <span>{{ field.name }}</span>
                          </template>
                        </ux-table-column>
                      </ux-grid>
                    </div>
                  </div>
                </el-tab-pane>
              </el-tabs>
            </el-row>
            <div slot="footer" class="dialog-footer">
              <el-button v-show="active === 1" :disabled="disabledNext" @click="next">{{
                $t('fu.steps.next')
              }}
              </el-button>
              <el-button v-show="active === 2" @click="before">{{ $t('fu.steps.prev') }}</el-button>
              <el-button v-show="active === 2" @click="saveItem">{{ $t('commons.save') }}</el-button>
            </div>
          </el-dialog>

          <el-form-item
            v-if="form.type !== 'es' && form.type !== 'api'"
            :label="$t('datasource.host')"
            prop="configuration.host"
          >
            <el-input v-model="form.configuration.host" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type=='es'"
            :label="$t('datasource.datasource_url')"
            prop="configuration.url"
          >
            <el-input
              v-model="form.configuration.url"
              :placeholder="$t('datasource.please_input_datasource_url')"
              autocomplete="off"
            />
          </el-form-item>

          <el-form-item
            v-if="form.type !== 'es' && form.type !== 'api'"
            :label="$t('datasource.data_base')"
            prop="configuration.dataBase"
          >
            <el-input v-model="form.configuration.dataBase" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type=='oracle' && form.type !== 'api'"
            :label="$t('datasource.oracle_connection_type')"
            prop="configuration.connectionType"
          >
            <el-radio v-model="form.configuration.connectionType" label="sid">{{
              $t('datasource.oracle_sid')
            }}
            </el-radio>
            <el-radio v-model="form.configuration.connectionType" label="serviceName">
              {{ $t('datasource.oracle_service_name') }}
            </el-radio>
          </el-form-item>

          <el-form-item v-if="form.type=='hive' " :label="$t('datasource.auth_method')">
            <el-select
              v-model="form.configuration.authMethod"
              class="select-width"
            >
              <el-option
                v-for="item in authMethodList"
                :key="item.id"
                :label="item.label"
                :value="item.id"
              />
            </el-select>
          </el-form-item>

          <el-form-item
            v-if="form.type === 'hive' && form.configuration.authMethod === 'kerberos'"
            :label="$t('datasource.client_principal')"
          >
            <el-input v-model="form.configuration.username" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type === 'hive' && form.configuration.authMethod === 'kerberos'"
            :label="$t('datasource.keytab_Key_path')"
          >
            <el-input v-model="form.configuration.password" autocomplete="off" show-password />
            <p>
              {{ $t('datasource.kerbers_info') }}
            </p>
          </el-form-item>

          <span v-if="form.type === 'hive' && form.configuration.authMethod === 'kerberos'" />

          <el-form-item
            v-if="form.type !== 'es' && form.type !== 'api' && form.configuration.authMethod !== 'kerberos'"
            :label="$t('datasource.user_name')"
          >
            <el-input v-model="form.configuration.username" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type !== 'es' && form.type !== 'api' && form.configuration.authMethod !== 'kerberos'"
            :label="$t('datasource.password')"
          >
            <el-input v-model="form.configuration.password" autocomplete="off" show-password />
          </el-form-item>

          <el-form-item
            v-if="form.type ==='es'"
            :label="$t('datasource.user_name')"
          >
            <el-input v-model="form.configuration.esUsername" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type ==='es'"
            :label="$t('datasource.password')"
          >
            <el-input v-model="form.configuration.esPassword" autocomplete="off" show-password />
          </el-form-item>

          <el-form-item
            v-if="form.type !=='es' && form.type!=='oracle' && form.type !== 'api'"
            :label="$t('datasource.extra_params')"
          >
            <el-input v-model="form.configuration.extraParams" autocomplete="off" />
          </el-form-item>

          <el-form-item
            v-if="form.type !=='es' && form.type !== 'api'"
            :label="$t('datasource.port')"
            prop="configuration.port"
          >
            <el-input v-model="form.configuration.port" autocomplete="off" type="number" min="0" />
          </el-form-item>

          <el-form-item
            v-if="form.type=='oracle' || form.type=='sqlServer' || form.type=='pg' || form.type=='redshift' || form.type=='db2'"
          >
            <el-button icon="el-icon-plus" size="mini" @click="getSchema()">{{
              $t('datasource.get_schema')
            }}
            </el-button>
          </el-form-item>

          <el-form-item
            v-if="form.type=='oracle' || form.type=='sqlServer' || form.type=='pg' || form.type=='redshift' || form.type=='db2'"
            :label="$t('datasource.schema')"
          >
            <el-select
              v-model="form.configuration.schema"
              filterable
              :placeholder="$t('datasource.please_choose_schema')"
              class="select-width"
            >
              <el-option v-for="item in schemas" :key="item" :label="item" :value="item" />
            </el-select>
          </el-form-item>

          <el-form-item v-if="form.type=='oracle'" :label="$t('datasource.charset')">
            <el-select
              v-model="form.configuration.charset"
              filterable
              :placeholder="$t('datasource.please_choose_charset')"
              class="select-width"
            >
              <el-option v-for="item in datasourceType.charset" :key="item" :label="item" :value="item" />
            </el-select>
          </el-form-item>

          <el-collapse v-if="form.type !=='es' && form.type !== 'api' && form.type !== 'mongo'">
            <el-collapse-item :title="$t('datasource.priority')" name="1">
              <el-form-item :label="$t('datasource.initial_pool_size')" prop="configuration.initialPoolSize">
                <el-input
                  v-model="form.configuration.initialPoolSize"
                  autocomplete="off"
                  type="number"
                  min="0"
                  size="small"
                />
              </el-form-item>
              <el-form-item :label="$t('datasource.min_pool_size')" prop="configuration.minPoolSize">
                <el-input v-model="form.configuration.minPoolSize" autocomplete="off" type="number" min="0" />
              </el-form-item>
              <el-form-item :label="$t('datasource.max_pool_size')" prop="configuration.maxPoolSize">
                <el-input v-model="form.configuration.maxPoolSize" autocomplete="off" type="number" min="0" />
              </el-form-item>
            </el-collapse-item>
          </el-collapse>
        </el-form>

      </el-col>
    </el-row>
  </div>
</template>

<script>

import i18n from '@/lang'
import { checkApiDatasource, getSchema } from '@/api/system/datasource'
import ApiHttpRequestForm from '@/views/system/datasource/ApiHttpRequestForm'
import LayoutContent from '@/components/business/LayoutContent'

export default {
  name: 'DsConfiguration',
  components: {
    ApiHttpRequestForm,
    // eslint-disable-next-line vue/no-unused-components
    LayoutContent
  },
  props: {
    disabled: {
      type: Boolean,
      default() {
        return false
      }
    },
    method: String,
    request: {},
    response: {},
    datasourceType: {},
    showScript: {
      type: Boolean,
      default: true
    },
    form: {
      type: Object,
      default() {
        return {
          configuration: {
            initialPoolSize: 5,
            extraParams: '',
            minPoolSize: 5,
            maxPoolSize: 50,
            maxIdleTime: 30,
            acquireIncrement: 5,
            idleConnectionTestPeriod: 5,
            connectTimeout: 5
          },
          apiConfiguration: []
        }
      }
    }
  },
  data() {
    return {
      rule: {
        name: [{ required: true, message: i18n.t('datasource.input_name'), trigger: 'blur' },
          { min: 2, max: 25, message: i18n.t('datasource.input_limit_2_25', [2, 25]), trigger: 'blur' }],
        desc: [{ min: 2, max: 50, message: i18n.t('datasource.input_limit_2_50'), trigger: 'blur' }],
        type: [{ required: true, message: i18n.t('datasource.please_choose_type'), trigger: 'blur' }],
        'configuration.dataBase': [{
          required: true,
          message: i18n.t('datasource.please_input_data_base'),
          trigger: 'blur'
        }],
        'configuration.connectionType': [{
          required: true,
          message: i18n.t('datasource.please_select_oracle_type'),
          trigger: 'blur'
        }],
        'configuration.username': [{
          required: true,
          message: i18n.t('datasource.please_input_user_name'),
          trigger: 'blur'
        }],
        'configuration.password': [{
          required: true,
          message: i18n.t('datasource.please_input_password'),
          trigger: 'blur'
        }],
        'configuration.host': [{ required: true, message: i18n.t('datasource.please_input_host'), trigger: 'blur' }],
        'configuration.url': [{ required: true, message: i18n.t('datasource.please_input_url'), trigger: 'blur' }],
        'configuration.port': [{ required: true, message: i18n.t('datasource.please_input_port'), trigger: 'blur' }],
        'configuration.initialPoolSize': [{
          required: true,
          message: i18n.t('datasource.please_input_initial_pool_size'),
          trigger: 'blur'
        }],
        'configuration.minPoolSize': [{
          required: true,
          message: i18n.t('datasource.please_input_min_pool_size'),
          trigger: 'blur'
        }],
        'configuration.maxPoolSize': [{
          required: true,
          message: i18n.t('datasource.please_input_max_pool_size'),
          trigger: 'blur'
        }],
        'configuration.maxIdleTime': [{
          required: true,
          message: i18n.t('datasource.please_input_max_idle_time'),
          trigger: 'blur'
        }],
        'configuration.acquireIncrement': [{
          required: true,
          message: i18n.t('datasource.please_input_acquire_increment'),
          trigger: 'blur'
        }],
        'configuration.connectTimeout': [{
          required: true,
          message: i18n.t('datasource.please_input_connect_timeout'),
          trigger: 'blur'
        }],
        'url': [{ required: true, message: i18n.t('datasource.please_input_url'), trigger: 'blur' }]
      },
      api_table_title: '',
      schemas: [],
      canEdit: false,
      originConfiguration: {},
      edit_api_item: false,
      add_api_item: true,
      active: 0,
      defaultApiItem: {
        name: '',
        url: '',
        method: 'GET',
        dataMethod: 'jsonpath',
        request: {
          headers: [{}],
          body: {
            'type': '',
            'raw': '',
            'kvs': []
          }
        },
        fields: []
      },
      apiItem: {
        status: '',
        name: '',
        url: '',
        method: 'GET',
        dataPath: '',
        dataMethod: 'jsonpath',
        request: {
          headers: [],
          body: {
            'type': '',
            'raw': '',
            'kvs': []
          },
          authManager: {}
        },
        fields: []
      },
      reqOptions: [{ id: 'GET', label: 'GET' }, { id: 'POST', label: 'POST' }],
      loading: false,
      responseData: { type: 'HTTP', responseResult: {}, subRequestResults: [] },
      api_step2_active_name: 'first',
      fieldTypes: [
        { label: this.$t('dataset.text'), value: 0 },
        { label: this.$t('dataset.time'), value: 1 },
        { label: this.$t('dataset.value'), value: 2 },
        { label: this.$t('dataset.value') + '(' + this.$t('dataset.float') + ')', value: 3 },
        { label: this.$t('dataset.location'), value: 5 }
      ],
      height: 500,
      disabledNext: false,
      authMethodList: [
        {
          id: 'passwd',
          label: i18n.t('datasource.passwd')
        }, {
          id: 'kerberos',
          label: 'Kerberos'
        }],
      // 支持自选API返回数据字段
      dataMethodOptions: [{ id: 'jsonpath', label: 'JsonPath' }, { id: 'choice', label: this.$t('datasource.data_choice') }],
      defaultProps: {
        children: 'children',
        label: 'label'
      },
      treeData: [],
      defaultTreeDatas: [],
      isDisabled: false,
      tableData: {},
      checkedKeys: []
    }
  },
  watch: {},
  created() {
  },
  methods: {
    getSchema() {
      this.$refs.DsConfig.validate(valid => {
        if (valid) {
          const data = JSON.parse(JSON.stringify(this.form))
          data.configuration = JSON.stringify(data.configuration)
          getSchema(data).then(res => {
            this.schemas = res.data
            this.$success(i18n.t('commons.success'))
          })
        } else {
          return false
        }
      })
    },
    next() {
      if (this.active === 1) {
        let hasRepeatName = false
        if (this.add_api_item) {
          this.form.apiConfiguration.forEach(item => {
            if (item.name === this.apiItem.name) {
              hasRepeatName = true
            }
          })
        } else {
          const index = this.form.apiConfiguration.indexOf(this.apiItem)
          for (let i = 0; i < this.form.apiConfiguration.length; i++) {
            if (i !== index && this.form.apiConfiguration[i].name === this.apiItem.name) {
              hasRepeatName = true
            }
          }
        }
        if (hasRepeatName) {
          this.$message.error(i18n.t('datasource.has_repeat_name'))
          return
        }
        this.$refs.apiItem.validate(valid => {
          if (valid) {
            const data = JSON.parse(JSON.stringify(this.apiItem))
            this.loading = true
            this.disabledNext = true
            checkApiDatasource(data).then(res => {
              this.loading = false
              this.disabledNext = false
              this.apiItem.status = 'Success'
              this.$success(i18n.t('commons.success'))
              this.active++
              // eslint-disable-next-line eqeqeq
              if (this.apiItem.dataMethod == 'jsonpath') {
                this.apiItem.fields = res.data.fields
                this.$refs.plxTable.reloadData(res.data.datas)
              } else {
                this.apiItem.fields = []
                this.isDisabled = true
                this.$refs.plxTable.reloadData(this.tableData)
                this.defaultTreeDatas = []
                this.$refs.tree.setCheckedKeys([])
                this.tableData = {}
                this.jsonDataToTreeData(res.data.datas[0])
              }
            }).catch(res => {
              this.loading = false
              this.disabledNext = false
            })
          } else {
            this.apiItem.fields = []
            return false
          }
        })
      }
    },
    before() {
      this.active--
    },
    closeEditItem() {
      this.active = 0
      this.edit_api_item = false
    },
    saveItem() {
      this.active = 0
      this.edit_api_item = false
      if (this.add_api_item) {
        debugger
        this.form.apiConfiguration.push(this.apiItem)
      }
    },
    addApiItem(item) {
      this.$nextTick(() => {
        if (this.$refs.apiItem) {
          this.$refs.apiItem.clearValidate()
        }
      })
      if (item) {
        if (!item.dataMethod) {
          item.dataMethod = 'jsonpath'
        }
        if (item.dataMethod !== 'jsonpath') {
          debugger
          this.isDisabled = true
          item.dataPath = item.fields.map(fiele => { return fiele.id }).join(',')
        }
        this.add_api_item = false
        this.api_table_title = this.$t('datasource.edit_api_table')
        this.apiItem = item
      } else {
        this.add_api_item = true
        this.apiItem = JSON.parse(JSON.stringify(this.defaultApiItem))
        this.api_table_title = this.$t('datasource.add_api_table')
      }
      this.active = 1
      this.edit_api_item = true
    },
    deleteItem(item) {
      this.form.apiConfiguration.splice(this.form.apiConfiguration.indexOf(item), 1)
    },
    validateApi(item) {
      if (!undefined) {
        this.$refs.apiItem.validate(valid => {
          if (valid) {
            const data = JSON.parse(JSON.stringify(this.apiItem))
            data.request = JSON.stringify(data.request)
            this.loading = true
            checkApiDatasource(data).then(res => {
              this.loading = false
              this.$success(i18n.t('commons.success'))
              this.apiItem.fields = res.data.fields
              this.$refs.plxTable.reloadData(res.data.datas)
            }).catch(res => {
              this.loading = false
            })
          } else {
            return false
          }
        })
      }
    },
    checkDataMethod() {
      if (this.apiItem.dataMethod === 'jsonpath') {
        this.isDisabled = false
      } else {
        this.isDisabled = true
      }
    },
    formatData(params) {
      const data = params
      if (!data) return
      data.map((item) => {
        if (item.hasOwnProperty('children') && item.children.length > 0) {
          item.disabled = true
          this.formatData(item.children)
        }
      })
      return data
    },
    treeCheckedChange(data, isChecked) {
      if (isChecked) {
        let has = false
        for (let i = 0; i < this.apiItem.fields.length; i++) {
          // eslint-disable-next-line eqeqeq
          if (data.id == this.apiItem.fields[i].id) {
            // eslint-disable-next-line no-const-assign
            has = true
            break
          }
        }
        this.checkedKeys.push(data.id) // id为tree的node-key属性
        this.$refs.tree.setCheckedKeys(this.checkedKeys)
        // this.$set(this.tableData, data.id , data.fieldData)
        if (!has) {
          this.apiItem.fields.push(data)
          this.$set(this.tableData, data.id, data.fieldData)
          this.$refs.plxTable.reloadData([this.tableData])
        }
      } else {
        delete this.tableData[data.id]
        this.checkedKeys = this.checkedKeys.filter(function(item) { return item !== data.id })
        this.apiItem.fields = this.apiItem.fields.filter(function(item) { return item.id !== data.id })
      }
    },
    jsonDataToTreeData(jsonData) {
      if (Object.prototype.toString.call(jsonData).indexOf('Object') !== -1) {
        this.defaultTreeDatas = []
        const keys = Object.keys(jsonData)
        for (let i = 0; i < keys.length; i++) {
          const a = {
            id: keys[i],
            label: keys[i],
            path: keys[i],
            originName: keys[i],
            name: keys[i],
            size: 65535,
            deExtractType: 0,
            deType: 0,
            extField: 0,
            children: []
          }
          this.jsonDataToTreeDataDG(a, jsonData[keys[i]])
          this.defaultTreeDatas.push(a)
        }
        this.treeData = this.formatData(this.defaultTreeDatas)
      }
    },
    jsonDataToTreeDataDG(defaultTreeData, value) {
      // eslint-disable-next-line eqeqeq
      if ((value && (value + '').indexOf('{') == 0)) {
        if (Object.prototype.toString.call(value).indexOf('String') !== -1) {
          const params = JSON.parse(value)
          const keys = Object.keys(params)
          for (let i = 0; i < keys.length; i++) {
            const b = {}
            b.id = keys[i]
            b.label = keys[i]
            b.children = []
            b.path = defaultTreeData.path + '.' + keys[i]
            b.originName = keys[i]
            b.name = keys[i]
            b.size = 65535
            b.deExtractType = 0
            b.deType = 0
            b.extField = 0
            const bValue = params[keys[i]]
            try {
              if (Object.prototype.toString.call(bValue).indexOf('Object') !== -1) {
                // eslint-disable-next-line no-const-assign
                bValue = JSON.stringify(bValue)
              }
            } catch (error) {
              console.log(error)
            }
            this.jsonDataToTreeDataDG(b, bValue)
            defaultTreeData.children.push(b)
          }
        }
      } else {
        defaultTreeData['fieldData'] = value
      }
    }
  }

}
</script>

<style scoped>
.ms-query {
  background: #409EFF;
  color: white;
  height: 18px;
  border-radius: 42%;
}

.ms-header {
  background: #409EFF;
  color: white;
  height: 18px;
  border-radius: 42%;
}

.request-tabs {
  margin: 20px;
  min-height: 200px;
}

.ms-el-link {
  float: right;
  margin-right: 45px;
}
.tab-pane-main{
  display: flex;
  height: 100%;
}
.tab-pane-right{
  overflow: auto;
  float:right;
  width:100%;
  padding: 8px;
}
.tab-pane-left{
  float:left;
  overflow-y: auto;
  padding: 8px;
  width: 30%;
  height: 500px;
}
</style>
