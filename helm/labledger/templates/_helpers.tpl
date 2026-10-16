{{- define "labledger.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "labledger.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 45 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" .Release.Name | trunc 45 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- define "labledger.labels" -}}
app.kubernetes.io/name: {{ include "labledger.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end -}}
{{- define "labledger.selectorLabels" -}}
app.kubernetes.io/name: {{ include "labledger.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "labledger.backendImage" -}}
{{- printf "%s:%s" .Values.backend.image.repository (required "backend.image.tag is required (full git SHA or explicit local override)" .Values.backend.image.tag) -}}
{{- end -}}
{{- define "labledger.frontendImage" -}}
{{- printf "%s:%s" .Values.frontend.image.repository (required "frontend.image.tag is required (full git SHA or explicit local override)" .Values.frontend.image.tag) -}}
{{- end -}}
{{- define "labledger.databaseEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret }}
      key: {{ .Values.database.urlKey }}
{{- end -}}
{{- define "labledger.securityContext" -}}
runAsNonRoot: true
runAsUser: 10001
runAsGroup: 10001
fsGroup: 10001
seccompProfile:
  type: RuntimeDefault
{{- end -}}
{{- define "labledger.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: [ALL]
readOnlyRootFilesystem: true
{{- end -}}
