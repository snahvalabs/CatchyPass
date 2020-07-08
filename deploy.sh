# Decryption for Travis CI
openssl aes-256-cbc -K $encrypted_b76db231b579_key -iv $encrypted_b76db231b579_iv -in catchypass-183fad22a5a8.json.enc -out catchypass-183fad22a5a8.json -d
# Connect to GCP
curl https://sdk.cloud.google.com | bash > /dev/null;
source $HOME/google-cloud-sdk/path.bash.inc
gcloud components update kubectl
gcloud auth activate-service-account --key-file catchypass-183fad22a5a8.json
gcloud config set project catchypass
gcloud config set compute/zone asia-east1
gcloud container clusters get-credentials catchypass-cluster
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Update the latest version for k8s to update the image
docker build -t lightcoker/catchypass-client:latest -t lightcoker/catchypass-client:$SHA -f ./client/Dockerfile ./client
docker build -t lightcoker/catchypass-server:latest -t lightcoker/catchypass-server:$SHA -f ./server/Dockerfile ./server
docker build -t lightcoker/catchypass-worker:latest -t lightcoker/catchypass-worker:$SHA -f ./worker/Dockerfile ./worker
docker build -t lightcoker/catchypass-mongo:latest -t lightcoker/catchypass-mongo:$SHA -f ./worker/Dockerfile  --build-arg MONGO_INITDB_ROOT_PASSWORD="$MONGO_PASSWORD_PROD" ./mongo
docker build -t lightcoker/catchypass-e2e:latest -t lightcoker/catchypass-e2e:$SHA -f ./worker/Dockerfile ./e2e

# Update the latest version to docker hub
docker push lightcoker/catchypass-client:latest
docker push lightcoker/catchypass-server:latest
docker push lightcoker/catchypass-worker:latest
docker push lightcoker/catchypass-mongo:latest
docker push lightcoker/catchypass-e2e:latest

# Update the latest version to docker hub for k8s to update images in deployment config 
docker push lightcoker/catchypass-client:$SHA
docker push lightcoker/catchypass-server:$SHA
docker push lightcoker/catchypass-worker:$SHA
docker push lightcoker/catchypass-mongo:$SHA
docker push lightcoker/catchypass-e2e:$SHA

# Setup k8s config
kubectl apply -f k8s
kubectl set image deployments/server-deployment node=lightcoker/catchypass-server:$SHA
kubectl set image deployments/worker-deployment python=lightcoker/catchypass-worker:$SHA
kubectl set image deployments/client-deployment react=lightcoker/catchypass-client:$SHA
kubectl set image deployments/mongodb-deployment mongodb=lightcoker/catchypass-mongo:$SHA
kubectl set image jobs/e2e-deployment e2e=lightcoker/mongo-e2e:$SHA
