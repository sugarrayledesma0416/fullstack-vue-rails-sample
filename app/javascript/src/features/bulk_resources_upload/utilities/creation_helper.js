import { getFromEndpoint } from 'music';
import { ref } from 'vue';

export const checkCreationInProgress = async (rootUrl) => {
    return new Promise((resolve) => {
        getFromEndpoint(
            `${rootUrl}/creation_in_progress_status`,
            (response) => {
                resolve(response);
            }
        );
    });
}
