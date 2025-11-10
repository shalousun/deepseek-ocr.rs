ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04

FROM registry.cn-shanghai.aliyuncs.com/shalousun/ubuntu-nvidia-cuda:12.4.1-cudnn-devel-ubuntu22.04 as compile
RUN apt-get update
RUN apt-get install -y curl
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

COPY . /compile
WORKDIR /compile
ARG CUDA_COMPUTE_CAP=80
RUN . "$HOME/.cargo/env" && cargo build --release --features cuda

FROM registry.cn-shanghai.aliyuncs.com/shalousun/ubuntu:${UBUNTU_VERSION}
COPY --from=compile /compile/target/release/deepseek-ocr-cli    /usr/local/bin/deepseek-ocr-cli
COPY --from=compile /compile/target/release/deepseek-ocr-server /usr/local/bin/deepseek-ocr-server
# cudart, curand, cublas, cublasLt
COPY --from=compile /usr/local/cuda/lib64/libcudart.so.* /usr/local/cuda/lib64/
COPY --from=compile /usr/local/cuda/lib64/libcurand.so.* /usr/local/cuda/lib64/
COPY --from=compile /usr/local/cuda/lib64/libcublas.so.* /usr/local/cuda/lib64/
COPY --from=compile /usr/local/cuda/lib64/libcublasLt.so.* /usr/local/cuda/lib64/
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

ENTRYPOINT ["/usr/local/bin/deepseek-ocr-server"]
