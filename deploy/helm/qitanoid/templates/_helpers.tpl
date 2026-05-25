{{- define "qitanoid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "qitanoid.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "qitanoid.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "qitanoid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "qitanoid.labels" -}}
helm.sh/chart: {{ include "qitanoid.chart" . }}
app.kubernetes.io/name: {{ include "qitanoid.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "qitanoid.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qitanoid.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "qitanoid.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "qitanoid.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "qitanoid.sessionServiceAccountName" -}}
{{- if .Values.session.serviceAccount.create -}}
{{- default (printf "%s-session" (include "qitanoid.fullname" .)) .Values.session.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.session.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "qitanoid.runtimeConfigMapName" -}}
{{- if .Values.session.runtimeScripts.existingConfigMap -}}
{{- .Values.session.runtimeScripts.existingConfigMap -}}
{{- else -}}
{{- printf "%s-runtime" (include "qitanoid.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "qitanoid.hubServiceName" -}}
{{- include "qitanoid.fullname" . -}}
{{- end -}}

{{- define "qitanoid.uiServiceName" -}}
{{- printf "%s-ui" (include "qitanoid.fullname" .) -}}
{{- end -}}

{{- define "qitanoid.redisServiceName" -}}
{{- printf "%s-redis" (include "qitanoid.fullname" .) -}}
{{- end -}}

{{- define "qitanoid.videoS3SecretName" -}}
{{- if .Values.video.storage.s3.existingSecret -}}
{{- .Values.video.storage.s3.existingSecret -}}
{{- else -}}
{{- printf "%s-video-s3" (include "qitanoid.fullname" .) -}}
{{- end -}}
{{- end -}}
